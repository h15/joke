package Mojolicious::Plugin::Forum::Controller::Threads;
use Mojo::Base 'Mojolicious::Controller';

sub index {
	my $self = shift;
	
	my @threads = $self->data->list( threads => '*', { parent_id => 0 }, ['id'], 20, $self->param('offset') );
	
	map {
        $_ = $self->data->read_one( posts => {id => $_->{post_id}} )
    } @threads;
	
	$self->stash( threads => \@threads );
    $self->render;
}

sub read {
	my $self = shift;
	
    my $thread = $self->data->read_one( threads => {id => $self->param('id')}   );
    my $parent = $self->data->read_one( threads => {id => $thread->{parent_id}} );
    
    return $self->error("Thread does not exist!") unless defined $thread;
    
    my $parent_post = $self->data->read_one( posts => {id => $thread->{post_id}} );
    my @posts = $self->data->list( posts => '*', {thread_id => $self->param('id')}, ['id'], 20, $self->param('offset') );
    
    return $self->error("Thread is empty!") unless scalar @posts;
    
    my $head = ( $posts[0]->{id} != $thread->{post_id} ?
        $self->data->read_one( posts => {id => $thread->{post_id}} ):
        $posts[0]
    );
    
    my @threads = $self->data->list( threads => '*', {parent_id => $self->param('id')}, ['id'], 20, $self->param('offset') );
    
    map {
        $_ = $self->data->read_one( posts => {id => $_->{post_id}} )
    } @threads;
    
    $self->stash(
        head => $head,
        parent => $parent_post,
        threads => \@threads,
        posts => \@posts
    );
    
    $self->render;
}

sub create {
    my $self = shift;
    
    $self->data->create( threads => {
        parent_id => $self->param('parent_id'),
        post_id   => $self->param('post_id'),
    });
    
    $self->redirect_to( 'threads_read', id => $self->param('parent_id') );
}

sub update {
    my $self = shift;
    
    $self->data->update( threads =>
        {
            parent_id => $self->param('parent_id'),
            post_id   => $self->param('post_id'),
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

