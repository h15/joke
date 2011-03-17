package CodeWars::Controller::Users;

use base 'Mojolicious::Controller';

sub read {
    my $self = shift;
    
	# Get accounts by id.
	my @users = $self->select( users => '*', { id => $self->stash('id') } );
    
    $self->error("User with this id doesn't exist!") if $#users;
    
    if( $self->user->{'id'} != 1                        # not Anonymous
        && $self->stash('id') == $self->user->{'id'}    # and Self
        || $self->user->is_admin() ) {                   # or  Admin.
        
        $self->read_extended(@users);
    }

    $self->stash( user => $users[0] );

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
