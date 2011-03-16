package Mojolicious::Plugin::Email;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app, $conf ) = @_;
    
    $app->helper (
        mail => sub {
            # $self->mail( confirm => {mail => "me@ho.me"} )
            my ($self, $action, $data) = @_;
            
            my %actions = {
                confirm => \confirm($data),
            };
            
            $actions{$action};
        }
    );
}

sub confirm {
    my ($self, $data) = @_;
    
    $self->send (
        confirm =>
        {
            mail => $data->{'mail'},
            key  => $data->{'key'}
        }
    );
}

sub send {
    my ($self, $template, $data) = @_;

    my $body = $self->render_mail (
        controller  => 'mail',
        action      => $template,
        %$data
    );
    
    $self->IS( mail => $data->{'mail'} );
    
    $self->sendMail (
        mail =>
        {
            To      => $data->{'mail'},
            Subject => "Hello from LorCode!",
            Data    => $body,
        }
    );

    $self->done('Check your e-mail.');
}

1;
