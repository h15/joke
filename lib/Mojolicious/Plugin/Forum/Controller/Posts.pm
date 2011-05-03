package Mojolicious::Plugin::Forum::Controller::Posts;
use Mojo::Base 'Mojolicious::Controller';

sub read {
    my $self = shift;
    
    my $post   = $self->data->read_one( posts   => {id => $self->param('post')} );
    my $thread = $self->data->read_one( threads => {id => $post->{thread_id}}   );
    
    my $head = ( $post->{id} != $thread->{post_id} ?
        $self->data->read_one( posts => {id => $thread->{post_id}} ):
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
    
    #
    #   TODO: ACL by thread_id
    #
    
    my $id = $self->param('thread');
    
    if ( $self->param('thread') == 0 ) {
        $id = $self->data->create( threads => {
            parent_id => 0,
            post_id   => 0
        });
        
        return $self->error("Cann't save post.") unless $id;   
    }
    
    my $thread = $self->data->read_one( threads => {id => $id} );
    
    my $parent = ( +$self->param('parent_id') ?
        $self->param('parent_id') :
        $thread->{post_id}
    );
    
    $parent ||= 0;
    
    $id = $self->data->create( posts => {
        thread_id => $thread->{id},
        parent_id => $parent,
        post_time => time,
        author    => $self->user->data->{id},
        text      => $self->param('text'),
    });
    
    
    if ( $thread->{post_id} == 0 ) {
        $self->data->update( threads =>
            { post_id => $id },
            { id => $thread->{id} }
        );
    }
    
    $self->redirect_to('threads_read', id => $thread->{id});
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

