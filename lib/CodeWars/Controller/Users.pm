package CodeWars::Controller::Users;

use base 'Mojolicious::Controller';

sub read {
    our $self = shift;

    if( $self->param('id') == ${CodeWars::User}->{'id'}
            || ${CodeWars::User}->isAdmin ) {
        $self->read_extended();
        return;
    }

    my ($s,$i,$h,$d,$m,$Y) = localtime( ${CodeWars::User}->{'regdate'} );
    
    $Y += 1900;

    $self->stash(
        regdate => "$Y.$m.$d $h:$i:$s",
        name => ${CodeWars::User}->{'name'},
        isActive => ${CodeWars::User}->isActive(),
    );

    $self->render;
}

1;
