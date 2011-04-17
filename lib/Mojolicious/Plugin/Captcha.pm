package Mojolicious::Plugin::Captcha;
use Mojo::Base 'Mojolicious::Plugin';

use Storable 'freeze';

has version => 0.1;
has about   => 'Prevent bots attack.';
has depends => sub { [] };
has config  => sub { { driver => "recaptcha", conf => {} } };

sub joke {};

sub register {
    my ( $self, $app ) = @_;
    
    $app->plugins()->namespaces(['Mojolicious::Plugin::Captcha']);

    $app->plugin( $self->config->{'driver'}, $self );
    
    $app->data->update( plugins =>
        # fields
        { config  => freeze( $self->config ) },
        # where
        { name => 'Captcha' }
    );
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

