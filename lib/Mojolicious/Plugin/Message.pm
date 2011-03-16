package Mojolicious::Plugin::Message;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app ) = @_;
    
    $app->helper (
        # Should not use directly.
        msg => sub {
            # For example: (self, 'error', 'html',
            # { message => "Die, die, dive with me!" }).
            my ($self, $template, $format, $data) = @_;
            
            $format ||= 'html';
            
            $self->render (
                controller  => 'message',
                action      => $template,
                format      => $format,
                %$data
            );
        }
    );
    
    $app->helper(
        # Log and show error.
        error => sub {
            my ($self, $message, $format) = @_;
            $app->log->error($message);
            $self->msg( error => $format => { message => $message } );
        }
    );
    
    $app->helper(
        # Show "Done", be nice.
        done => sub {
            my ($self, $message, $format) = @_;
            $self->msg( done => $format => { message => $message } );
        }
    );
}

1;
