package CodeWars::Controller::Threads;

use base 'Mojolicious::Controller';

sub read {
	my $self = shift;
	my $db = CodeWars::DB->handler();
	
    my @posts = $db->select(
        'forum__posts', '*',
        {
            topic_id => $self->param('id')
        }
    )->hashes;

    $self->stash(
        posts => \@posts
    );
    
    $self->render;
}

1;
