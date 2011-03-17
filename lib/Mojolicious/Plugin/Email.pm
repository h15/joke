package Mojolicious::Plugin::Email;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.1';

sub register {
    my ( $self, $app, $conf ) = @_;
    
    $app->helper (
        mail => sub {
            return shift;
        }
    );
    
    $app->helper (
        confirm => sub {
            my ($self, $data) = @_;
            
            $self->send (
                confirm => $data
            );
        }
    );
    
    $app->helper (
        send => sub {
            my ($self, $template, $data) = @_;
            
            $self->stash (
                controller => "mail",
                action     => $template
            );
            
            my $body = $self->render_mail( %$data );
            
            $self->IS( mail => $data->{'mail'} );
            
            $self->send_mail (
                mail =>
                {
                    To      => $data->{'mail'},
                    Subject => $data->{'reason'} . "at LorCode.",
                    Data    => $body,
                }
            );
            
            $self->done('Check your e-mail.');
        }
    );
}

1;
