package Mojolicious::Plugin::Mail;
use Mojo::Base 'Mojolicious::Plugin';

use MIME::Lite;

has version => 0.1;
has about   => 'Plugin for Mail system.';
has depends => sub { [ qw/Message/ ] };
has config  => sub {{
    from => 'no-reply@lorcode.org'
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
    my ( $self, $app, $conf ) = @_;
    $conf ||= {};
    
    if ( defined %$conf ) {
        $self->config->{$_} = $conf->{$_} for keys %$conf;
    }
    
    $app->helper( mail => sub {
        my ( $self, $type, $mail, $title, $data ) = @_;
        
        $self->stash(%$data, title => $title);
        
        my $html = $self->render (
            partial    => 1,
            template   => "mail/$type"
        );
        
        MIME::Lite->new (
            From    => $conf->{from},
            To      => $mail,
            Subject => $self->l($title),
            Data    => $html,
        )->send("sendmail", "/usr/lib/sendmail -t");
    });
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

