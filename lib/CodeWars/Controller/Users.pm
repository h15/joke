package CodeWars::Controller::Users;

use base 'Mojolicious::Controller';

sub read {
    our $self = shift;

    if( $self->param('id') == ${CodeWars::User}->{'id'}
            || ${CodeWars::User}->isAdmin ) {
        $self->read_extended();
        return;
    }

    my ($sec,$min,$hour,$mday,$mon,$year) =
                        localtime( ${CodeWars::User}->{'regdate'} );
    $year += 1900;

    $self->stash(
        regdate => "$year.$mon.$mday $hour:$min:$sec",
        name => ${CodeWars::User}->{'name'},
        isActive => ${CodeWars::User}->isActive(),
    );

    $self->render;
}

1;
