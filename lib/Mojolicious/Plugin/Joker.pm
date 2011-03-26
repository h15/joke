use strict;
use warnings;

package Mojolicious::Plugin::Joker;

use base 'Mojolicious::Plugin';

our $VERSION = '0.1';

sub register {
    my( $self, $app ) = @_;
    
    my $session = $app->sessions;
    
    #
    #   Load core plugins.
    #

    $app->plugin('message');
    $app->plugin('data');
    $app->plugin( 'user' => { id => $session->{'user_id'} } );
    
    #
    #   Joker routes.
    #
    
    my $r = $app->routes;
    $r->namespace('Mojolicious::Plugin::Controller');
    
    # List of plugins, which I found in ./lib/Mojolicious/Plugin.
    $r->route('/joker')->to('joker#list')->name('joker_list');

    # Show one plugin.
    $r->route('/joker/:plugin')->via('get')->to('joker#read')
        ->name('joker_read');
    # Change config.
	$r->route('/joker/:plugin/:action')->via('post')->to('joker#update')
        ->name('joker_update');
	
	#
	#   Helpers.
	#
	
	# Recursive build html tables for config structure. Quick and dirty...
    $app->helper(
        # Show xmas^W config tree with changeable values.
        html_hash_tree => sub {
            my ( $self, $config ) = @_;
            
            my $ret = "<table>";
            
            for my $k ( keys %$config ) {
                $ret .= "<tr><td>$k</td><td name='$k'>";
                
                # Branch or leaf?
                unless ( ref $config->{$k} ) {
                    $ret .= "<input value='" . $config->{$k}
                         . "' class='changeable' name='$k-input' "
                         . "onClick=\"click_input('$k-input')\">";
                }
                else {
                    $ret .= $self->html_hash_tree( $config->{$k} );
                }
                
                $ret .= "</td></tr>";
            }
            
            $ret .= "</table>";
            return $ret;
        }
    );
    
	#
	#   Load active plugins.
	#
	
	
}

1;

package Mojolicious::Plugin::Controller::Joker;

use base 'Mojolicious::Controller';

use Data::Dumper;

# cRud
sub read {
    my $self = shift;
    
    my $path = $self->param('plugin');
    $path =~ s/::/\//g;
    $path = "./lib/$path.pm";
    
    # If module's file does not exist.
    return $self->error("Cann't read file $path!") unless -r $path;
    
    # Read joke by file path.
    my $info = $self->read_joke( $path );
    
    # 
    return $self->error( $self->param('plugin')
        . " does not have info about his self." ) unless $info;
    
    # Add joke to stash
    my $jokes = { $info->{'name'} => $info };
    
    my @plugins = $self->data->read( plugins => {
        name => $self->param('plugin')
    });
    
    # Add config info from db if joke exists
    if( exists $jokes->{ $plugins[0]->{'name'} } ) {
        $jokes->{ $plugins[0]->{'name'} }->{'config'} = $plugins[0];
    }
    
    $self->stash( jokes => $jokes );
    
    my $DATA = Mojo::Command->new->get_all_data( __PACKAGE__ );
    
    $self->content_for(
        body => $self->render( inline => $DATA->{'read.html.ep'} )
    );
    
    $self->render(
        inline => $DATA->{'base.html.ep'},
        title => $info->{'name'}
    );
}

#
#   List of plugins.
#

sub list {
    my $self = shift;
    
    my %jokes = $self->scan;
    
    #
    #   Get config form database and push config to joke if joke exists.
    #   $self->data->read('plugins') returns array of hashes.
    #
    
    for my $plugin ( $self->data->read('plugins') ) {
        if( exists $jokes{ $plugin->{'name'} } ) {
            $jokes{ $plugin->{'name'} }{'config'} = $plugin;
        }
    }
    
    $self->stash( jokes => \%jokes);
    
    my $DATA = Mojo::Command->new->get_all_data( __PACKAGE__ );
    
    $self->content_for(
        body => $self->render( inline => $DATA->{'list.html.ep'} )
    );
    
    $self->render( inline => $DATA->{'base.html.ep'}, title => 'list' );
}

sub update {
    
}

sub scan {
    my $self = shift;
    
    #
    #   Recursive get all files from $self->info('config')->{'scan_path'}.
    #
    
    my @dir = <./lib/Mojolicious/Plugin/*>;
    my @files;
    
    while( @dir ) {
        my $path = pop @dir;

        # if file
        push @files, $path   if -r $path;
        
        # if directory
        push @dir, <$path/*> if -d $path;
    }
    
    #
    #   Read all service information.
    #   $self->stash('jokes') will have hash (joke's name is a key)
    #   of hashes (info).
    #

    my %jokes;
    
    for my $joke ( @files ) {
        my $info = $self->read_joke($joke);
        
        # Don't read jokes without info.
        next unless $info;
        
        $jokes{ $info->{'name'} } = $info;
    }
    
    return %jokes;
}

#
#   Read module's params such as version, author, conditions.
#

sub read_joke {
    # Get path to module.
    my ($self, $module) = @_;
    
    # Get module name.
    $module = $self->path2module($module);
    
    # Needed info.
    # Dynamic load module.
    use lib $module;
    
    my $obj = bless {}, $module;
    my $info = $obj->info if defined *{$module . '::info'};
    
    no lib $module;
    
    # Info can be not defined...
    if( $info ) {
        $info->{'name'} = $module;
        
        return $info;
    }
    
    return 0;
}

sub path2module {
    my ($self, $path) = @_;
    
    my @waypoints = split /[\\\/]/, $path;
    $waypoints[-1] =~ s/\.pm$//i;
    
    # Remove "./lib/" from path.
    return join('::', @waypoints[2..$#waypoints]);
}

1;

__DATA__
@@ base.html.ep
<!doctype html>
<html>
    <head>
        <style>
.page {
	margin:0px auto;
	width:800px;
	color:#222;
	font-family:Sans, Arial;
}
a {
    color: #c62;
}
.rounded {
	padding: 5px;
	background: #eee;
	border: 1px solid #ddd;
	-moz-border-radius: 10px;
	-webkit-border-radius: 10px;
	border-radius: 10px;
	-khtml-border-radius: 10px;
}
.simple_table {
    border:0px;
    //width:600px;
}
.simple_table td {
    vertical-align: top;
    padding:2px 5px 2px 5px;
}
td.changeable {
    border:1px solid #ddd;
}
.alignright {
    float:right;
}
body {
    padding:0px;
    margin:0px;
}
img {
    border:0px;
}
.plugin {
    margin-top:5px;
    padding: 10px;
}
.actions {
    float:right;
}
.plugin a {
    text-decoration: none;
    color: #c62;
}
a.action:hover {
    background-color:#ddd;
}
.action {
    padding:5px 10px 5px 10px;
}
.plugins {
    margin:0px auto;
    width:600px;
}
.plugins h2 {
    color:#ccc;
}
a.on {
    font-weight:bold;
    color:darkred;
    font-family:"Times new roman";
    text-decoration: none;
}
a.off {
    font-weight:bold;
    color:#888;
    font-family:"Times new roman";
    text-decoration: none;
}
.changeable {
    border:1px solid #ddd;
    background:#eee;
    color: #222;
}
        </style>
        <link rel="icon" href="/img/joker/j64.png" type="image/x-icon" />
		<link rel="shortcut icon" href="/img/joker/j64.png" type="image/x-icon" />
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>Joker plugin system &rarr; <%= $title %></title>
    </head>
    <body>
        <div class=page>
            %= content_for 'body'
        </div>
--> </body>
</html>

@@ list.html.ep
% content_for body => begin
<div class="plugins">
<h2>Plugin list</h2>
%   my $jokes = $self->stash('jokes');
%   for my $plugin (values %$jokes) {
%       my ($stat, $do) = $plugin->{'active'} ? ('on','off') : ('off','on');
        <a href="<%= url_for('joker_read', plugin => $plugin->{'name'}) %>">
        <div class="plugin rounded">
            <%= $plugin->{'name'} %> (<%= $plugin->{'version'} %>)
            <div class="actions">
                <a class="action <%= $stat %>
                    rounded" href="<%= url_for('joker_update',
                        plugin => $plugin->{'name'}, action => $do) %>">J</a>
            </div>
        </div>
        </a>
%   }
</div>
<!-- End of body 
% end

@@ read.html.ep
% content_for body => begin
%   my $jokes = $self->stash('jokes');
%   for my $plugin (values %$jokes) {
%       my ($stat, $do) = $plugin->{'active'} ? ('on','off') : ('off','on');
<div class="plugins">
    <h2><a class="on rounded action" href="<%= url_for('joker_list') %>">J</a> &rarr;
        <%= $plugin->{'name'} %></h2>
    <div class="actions">
        <a class="action <%= $stat %> rounded" href="
        %= url_for('joker_update', plugin => $plugin->{'name'}, action => $do)
        ">J</a>
    </div>
%#
%#          PLUGIN's INFO
%#
<div class="plugins rounded">
    <table class="simple_table">
        <tr>
            <td>version</td>
            <td><%= $plugin->{'version'} %></td>
        </tr>
        <tr>
            <td>about</td>
            <td><%= $plugin->{'about'} %></td>
        </tr>
        <tr>
            <td>depends</td>
            <td>
%#
%#          LIST OF DEPS
%#
% for my $dep ( @{$plugin->{'depends'}} ) {
<a href="<%= url_for('joker_read', plugin => "Mojolicious::Plugin::$dep")%>
"><%= $dep %></a>&nbsp;
% }
            </td>
        </tr>
        <tr>
            <td>config</td>
            <td>
<form action="<%= url_for('joker_update', plugin => $plugin->{'name'}) %>"
    method=POST>
    %== html_hash_tree( $plugin->{'config'} )
    <input type="submit" class="alignright">
</form>
            </td>
        </tr>
        <tr>
            <td>author</td>
            <td><%= $plugin->{'author'} %></td>
        </tr>
    </table>
</div>
</div>
%   }
<!-- End of body 
% end

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

