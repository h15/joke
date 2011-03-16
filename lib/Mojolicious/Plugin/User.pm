package Mojolicious::Plugin::User;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.1';

sub register {
    my ( $self, $app, $id ) = @_;
    
    # Anonymous has 1st id.
    $id = 1 unless $id =~ m/^\d+$/;
    
    my $user = CodeWars::Plugin::User::User->new (
        $app->select( users => '*', { id => $id } )
    );
    
    $app->helper (
        user => sub {
            return $user;
        }
    );
}

1;

package CodeWars::Plugin::User::User;

sub new {
    my ($self, @users) = @_;
    
    $self->error("User with this id does not exist.") if $#users;

    bless $users[0], $self;
}

sub isActive {
    my $self = shift;
    return 1 if $self->{'inactive_reason'} == 0;
    return 0;
}

sub isAdmin {
    my $self = shift;
    
    # In soviet Russia^W^W phpbb3 it's true.
    return 1 if $self->{'role'} == 3;
    return 0;
}

1;

