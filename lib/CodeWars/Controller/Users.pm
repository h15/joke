package CodeWars::Controller::Users;

use base 'Mojolicious::Controller';

sub read {
    my $self = shift;
    my $db = CodeWars::DB->handler();
    
	# Get accounts by id.
	my @users = $db->select(
        'forum__users', '*',
        {
            id => $self->stash('id')
        }
    )->hashes;
    
    if( $self->stash('id') == ${CodeWars::User}->{'id'}
            || ${CodeWars::User}->isAdmin() ) {
        $self->read_extended(@users);
        return;
    }

    $self->stash(
        user => $users[0]
    );

    $self->render;
}

sub read_extended {
    my $self = shift;
    my @users = @_;
    
    $self->render(
        action => 'read_extended',
    );
}

1;
