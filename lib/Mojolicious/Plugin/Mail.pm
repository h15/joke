package Mojolicious::Plugin::Mail;
use Mojo::Base 'Mojolicious::Plugin';

has version => 0.1;
has about   => 'Plugin for Mail system.';
has depends => sub { [ qw/Message/ ] };
has config  => sub {{
    sub_plugin => 'Mail',
    conf       => {
        from     => 'no-reply@lorcode.org',
        encoding => 'base64',
        type     => 'text/html',
        how      => 'sendmail',
        howargs  => [ '/usr/sbin/sendmail -t' ]
    }
}};

sub joke {
    my ( $self, $app ) = @_;
    
    my $plugin = $app->data->read_one( jokes => {name => 'Mail'} );
    $self->config( thaw $plugin->{config} ) if defined $plugin->{config} && length $plugin->{config};
    
    {
       version => $self->version,
       about   => $self->about,
       depends => $self->depends,
       config  => $self->config
    }
}

sub register {
    my ( $self, $app ) = @_;
    
    $self->joke( $app );
    
    $app->plugins->namespaces(['Mojolicious::Plugin::Mail']);
    $app->plugin( lc $self->config->{sub_plugin}, $self );

    # clean up
    $app->plugins->namespaces(['Mojolicious::Plugin']);
    
    $app->helper (
        confirm => sub {
            my ($self, $data) = @_;
            
            $self->send(confirm => $data);
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
