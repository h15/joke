package Mojolicious::Plugin::Mail;
use Mojo::Base 'Mojolicious::Plugin';

use Storable 'thaw';
use MIME::Lite;

has version => 0.1;
has about   => 'Plugin for Mail system.';
has depends => sub { [ qw/Message/ ] };
has config  => sub {{
    from => '',
    site => '',
}};

sub joke {
    my ( $self, $app ) = @_;
    {
       version => $self->version,
       about   => $self->about,
       depends => $self->depends,
       config  => $self->config
    }
}

sub register {
    my ( $plugin, $app, $conf ) = @_;

    my $plug = $app->data->read_one(jokes => {name => 'Mail'});
    
    $plugin->config(thaw $plug->{config}) if defined $plug->{config} && length $plug->{config};
    
    $app->helper( mail => sub {
        my ( $self, $type, $mail, $title, $data ) = @_;

        return $self->error('Not enough data for mail!') unless defined $type && defined $mail;
        $title ||= '';
        $data  ||= {};

        $self->stash(
            %$data,
            title => $title,
            host  => $plugin->config->{site},
        );
        
        my $html = $self->render (
            partial    => 1,
            template   => "mail/$type"
        );
        
        MIME::Lite->new (
            From    => $plugin->config->{from},
            To      => $mail,
            Subject => $self->l($title),
            Type    => 'text/html',
            Data    => $html,
        )->send;
    });
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

