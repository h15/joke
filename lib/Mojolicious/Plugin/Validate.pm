package Mojolicious::Plugin::Validate;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.1';

sub register {
    my ( $self, $app ) = @_;

    $app->helper (
        is => sub {
            my ($self, $type, $val) = @_;

            if  ( $type eq 'mail' ) {
                return 1 if $val =~ m/^[a-z0-9_\-.]+@[a-z0-9_\-.]+$/i;
            }

            return 0;
        }
    );
    
    $app->helper (
        IS => sub {
            my ($self, $type, $val) = @_;
            
            $self->error( "It's not $type!" ) unless $self->is($type, $val);
        }
    );
}

1;
