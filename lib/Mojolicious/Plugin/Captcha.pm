package Mojolicious::Plugin::Captcha;
use Mojo::Base 'Mojolicious::Plugin';

use Storable 'thaw';

has version => 0.1;
has about   => 'Prevent bots attack.';
has depends => sub { [] };
has config  => sub {{
    sub_plugin => "Simple",
    config     => {}
}};

sub joke {
    my ( $self, $app ) = @_;
    
    my $plugin = $app->data->read_one( jokes => {name => 'Captcha'} );
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
    
    $app->plugins->namespaces(['Mojolicious::Plugin::Captcha']);
    $app->plugin( lc $self->config->{sub_plugin}, $self );

    # clean up
    $app->plugins->namespaces(['Mojolicious::Plugin']);
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

