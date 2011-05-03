package Mojolicious::Plugin::Message;
use Mojo::Base 'Mojolicious::Plugin';

has version => 0.1;
has about   => 'Message system.';
has depends => sub { [] };
has config  => sub { {} };

sub joke {
    my $self = shift;    
    {
       version => $self->version,
       about   => $self->about,
       depends => $self->depends,
       config  => $self->config
    }
}

sub register {
    my ( $self, $app ) = @_;
    
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
    
    $app->helper(
        # Do not use it directly.
        msg => sub {
            # For example: (self, 'error', 'html',
            # { message => "Die, die, dive with me!" }).
            my ($self, $template, $format, $data) = @_;
            $format ||= 'html';
            
            $self->stash(
                %$data, 
                title => $template
            );
            
            $self->render(template => "message/$template");
        }
    );
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

