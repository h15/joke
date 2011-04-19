package Mojolicious::Plugin::Forum::Controller::Posts;
use Mojo::Base 'Mojolicious::Controller';

sub read {
    my $self = shift;
    
    my $post = [$self->data->read( posts => { id => $self->param('post') } )]->[0];
    my $thread = [$self->data->read( threads => { id => $post->{'thread_id'} } )]->[0];
    
    my $head = ( $post->{id} != $thread->{post_id} ?
        [$self->data->read( posts => { id => $thread->{post_id} } )]->[0]:
        $post
    );
    
    $self->stash(
        head => $head,
        post => $post
    );
    
    $self->render;
}

sub create {
    my $self = shift;
    
    my $thread = [$self->data->read( threads => { id => $self->param('id') } )]->[0];
    
    my $parent = ( +$self->param('parent_id') ?
        $self->param('parent_id') :
        $thread->{post_id}
    );
    
    $self->data->create( posts => {
        thread_id => $self->param('id'),
        parent_id => $parent,
        post_time => time,
        author    => $self->user->data->{id},
        text      => $self->param('text'),
    });
    
    $self->redirect_to('threads_read', id => $self->param('id'));
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

