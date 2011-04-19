package Mojolicious::Plugin::Forum::Controller::Threads;
use Mojo::Base 'Mojolicious::Controller';

sub read {
	my $self = shift;
	
    my $thread = [$self->data->read( threads => { id => $self->param('id') } )]->[0];
    my $parent = [$self->data->read( threads => { id => $thread->{'parent_id'} } )]->[0];
    
    return $self->error("Thread does not exist!") unless defined $thread;
    
    $parent_post = [$self->data->read( posts => { id => $thread->{'post_id'} } )]->[0];
    @posts = $self->data->read( posts => { thread_id => $self->param('id') } );
    
    return $self->error("Thread is empty!") unless scalar @posts;
    
    my $head = ( $post[0]->{id} != $thread->{post_id} ?
        [$self->data->read( posts => { id => $thread->{post_id} } )]->[0]:
        $post[0]
    );
    
    $self->stash(
        head => $head,
        parent => $parent_post,
        posts => \@posts
    );
    
    $self->render;
}

sub create {
    my $self = shift;
    
    $self->data->create( threads => {
        parent_id => $self->param('parent_id'),
        post_id => $self->param('post_id'),
    });
    
    $self->redirect_to( 'threads_read', id => $self->param('parent_id') );
}

sub update {
    my $self = shift;
    
    $self->data->update( threads =>
        {
            parent_id => $self->param('parent_id'),
            post_id => $self->param('post_id'),
        },
        { id => $self->param('id') }
    );
    
    $self->redirect_to( 'threads_read', id => $self->param('id') );
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

