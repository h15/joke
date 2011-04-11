package Mojolicious::Plugin::Mail;

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
        about   => 'Plugin for Mail system.',
        fields  => {
        # Needed fields.
        },
        depends => [ qw/Message/ ],
        config  => {
            sander => {
                from     => 'no-reply@lorcode.org',
                encoding => 'base64',
                type     => 'text/html',
                how      => 'sendmail',
                howargs  => [ '/usr/sbin/sendmail -t' ]
            }
        }
    };
    
    return $info->{$field} if $field;
    return $info;
}

sub register {
    my ( $self, $app ) = @_;
    
    $app->plugin( mail::mail => $self->info('config')->{'sander'} );
    
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
