package CodeWars::Controller::Threads;

use base 'Mojolicious::Controller';

sub read {
	my $self = shift;
	
    my @posts = $self->select(
        posts => '*' =>
        {
            topic_id => $self->param('id')
        }
    );
    
    $self->error("Thread with this id doesn't exist!") unless scalar @posts;

    $self->stash(
        posts => \@posts
    );
    
    $self->render;
}

#sub create {
#
#}

1;

