package Mojolicious::Plugin::Message;

use strict;
use warnings;

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
        about   => 'Message system.',
        # Yeah! No fields, no deps, no configs!
        fields  => {},
        depends => [],
        config  => {}
    };
    
    return $info->{$field} if $field;
    return $info;
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
}

sub msg {
    # For example: (self, 'error', 'html',
    # { message => "Die, die, dive with me!" }).
    my ($self, $template, $format, $data) = @_;
    
    $format ||= 'html';
    
    $self->render (
        template => "mojolicious/plugin/message/$template",
        format   => $format,
        %$data
    );
}

1;

__DATA__
@@ mojolicious/plugin/message/style.css
.page {
	margin:0px auto;
	width:800px;
	color:#222;
	font-family:Sans, Arial;
}
.error {
    width: 600px;
    background: #fee;
    border: 1px solid #fcc;
    padding: 50px;
    margin: 50px auto;
    text-align:center;
}
.done {
    width: 600px;
    background: #efe;
    border: 1px solid #cfc;
    padding: 50px;
    margin: 50px auto;
    text-align:center;
}
.rounded {
	padding: 5px;
	background: #eee;
	border: 1px solid #ddd;
//
	-moz-border-radius: 10px;
	-webkit-border-radius: 10px;
	border-radius: 10px;
	-khtml-border-radius: 10px;
}
.center {
    margin: 50px auto;
}

@@ mojolicious/plugin/message/base.html.ep
<!doctype html>
<html>
    <head>
        <%= content_for 'header' %>
%= stylesheet 'mojolicious/plugin/message/style.css'
        <title><%= content_for 'title' %></title>
    </head>
    <body>
        <%= content_for 'body' %>
    </body>
</html>

@@ mojolicious/plugin/message/error.html.ep
% extends 'mojolicious/plugin/message/base.html.ep';
<% content_for title => begin %>
    <%=l "Error!" %>
<% end %>
<% content_for body => begin %>
    <div class=page>
        <div class="rounded error">
            <%=l $message %>
        </div>
    </div>
<% end %>

@@ mojolicious/plugin/message/done.html.ep
% extends 'mojolicious/plugin/message/base.html.ep';
<% content_for title => begin %>
    <%=l "Done!" %>
<% end %>
<% content_for body => begin %>
    <div class=page>
        <div class="rounded done">
            <%=l $message %>
        </div>
    </div>
<% end %>

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

