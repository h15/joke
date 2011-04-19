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
    
            my $DATA = Mojo::Command->new->get_all_data( __PACKAGE__ );
            
            $self->stash( %$data );
            
            $self->content_for(
                body => $self->render(
                    inline => $DATA->{$template . '.html.ep'}
                )
            );
            
            $self->render(
                inline => $DATA->{'base.html.ep'},
                title => $template
            );
            
            return;
        }
    );
}

1;

__DATA__
@@ base.html.ep
<!doctype html>
<html>
    <head>
%= stylesheet '/css/main.css';
        <title>Joker &rarr; <%= $title %></title>
    </head>
    <body>
        <%= content_for 'body' %>
--> </body>
</html>

@@ error.html.ep
% content_for body => begin
    <div class=page>
        <div class="rounded error">
            <%= $self->stash('message') %>
        </div>
    </div><!--
% end

@@ done.html.ep
% content_for body => begin
    <div class=page>
        <div class="rounded done">
            <%= $message %>
        </div>
    </div><!--
% end

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

