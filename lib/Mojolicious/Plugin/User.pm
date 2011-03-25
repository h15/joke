package Mojolicious::Plugin::User;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.1';

#
#   Info method for Joker plugin manager.
#

sub info {
    my ($self, $field) = @_;
    
    my $info = {
        version => $VERSION,
        author  => 'h15 <georgy.bazhukov@gmail.com>',
        about   => 'Plugin for Users system.',
        fields  => {
        # Needed fields.
        },
        depends => [ qw/Data Message Mail/ ],
        config  => {
        # May be should init admin here?
            cookies => 'some random string'
        }
    };
    
    return $info->{$field} if $field;
    return $info;
}

sub register {
    my ( $self, $app ) = @_;
    
    $app->secret( $self->info('config')->{'cookies'} );
    $app->sessions->default_expiration(3600*24*7);
    
    my $session = $app->sessions;
    my $id = $session->{'user_id'};
    
    # Anonymous has 1st id.
    $id ||= 1;
    
    my $user = Mojolicious::Plugin::User::User->new (
        $app->data->read( users => { id => $id } )
    );
    
    $app->helper (
        user => sub {
            return $user;
        }
    );
}

1;

package Mojolicious::Plugin::User::User;

sub new {
    my ($self, @users) = @_;
    
    $self->error("User with this id does not exist.") if $#users;

    bless $users[0], $self;
}

sub is_active {
    my $self = shift;
    return 1 if $self->{'inactive_reason'} == 0;
    return 0;
}

sub is_admin {
    my $self = shift;
    
    # In soviet Russia^W^W phpbb3 it's true.
    return 1 if $self->{'role'} == 3;
    return 0;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

