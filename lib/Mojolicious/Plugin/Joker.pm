use strict;
use warnings;

package Mojolicious::Plugin::Joker;

use base 'Mojolicious::Plugin';

use Storable 'thaw';

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
	$r->route('/joker/:plugin')->via('post')->to('joker#update')
        ->name('joker_update');
    # On / Off
    $r->route('/joker/:turn/:plugin')->to('joker#turn')->name('joker_turn');
	
    #
    #   Activate module if is_active.
    #
    
    my @plugins = $app->data->read (
        plugins => { is_active => 1 }
    );
    
    for my $plugin ( @plugins ) {
        # Hardcoded!!!
        # 21 - it's a length of "Mojolicious::Plugin::".
        # Should be fixed.
        $plugin->{'id'} = substr $plugin->{'id'}, 21;
        $app->plugin( lc $plugin->{'id'} );
    }
    
	#
	#   Helpers.
	#
	
	# Recursive build html tables for config structure. Quick and dirty.
    $app->helper(
        # Show xmas^W config tree with changeable values.
        html_hash_tree => sub {
            my ( $self, $config, $parent ) = @_;
            
            $parent ||= '';
            
            my $ret = "<table>";
            
            for my $k ( keys %$config ) {
                $ret .= "<tr><td>$k</td><td name='$parent-$k'>";
                
                # Branch or leaf?
                unless ( ref $config->{$k} ) {
                    $ret .= "<input value='" . $config->{$k}
                         . "' class='changeable' name='$parent-$k-input'>";
                }
                else {
                    $ret .= $self->html_hash_tree(
                        $config->{$k}, "$parent-$k" );
                }
                
                $ret .= "</td></tr>";
            }
            
            $ret .= "</table>";
            return $ret;
        }
    );	
}

1;

package Mojolicious::Plugin::Controller::Joker;
use Storable qw/freeze thaw/;
use Data::Dumper;

use base 'Mojolicious::Controller';

our $PLUG_PATH = './lib/Mojolicious/Plugin/';

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
    
    # If module has not info.
    return $self->error( $self->param('plugin')
        . " does not have info about his self." ) unless $info;
    
    #
    my $jokes = { $info->{'name'} => $info };
    
    my @plugins = $self->data->read( plugins => {
        id => $self->param('plugin')
    });
    
    # Add config info from db if joke exists
    if ( exists $jokes->{ $plugins[0]{'id'} } ) {
        $jokes->{ $plugins[0]{'id'} }->{'is_active'} =
            $plugins[0]{'is_active'};
        $jokes->{ $plugins[0]{'id'} }->{'config'} = thaw $plugins[0]{'config'} 
            if length $plugins[0]{'config'};
    }
    
    $self->stash(
        jokes => $jokes,
        title => $info->{'name'}
    );

    $self->data_render('read');
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
        if( exists $jokes{ $plugin->{'id'} } ) {
            $jokes{ $plugin->{'id'} }->{'is_active'} = $plugin->{'is_active'};
            $jokes{ $plugin->{'id'} }->{'config'} = thaw $plugin->{'config'}
                if length $plugin->{'config'};
        }
    }
    
    $self->stash(
        jokes => \%jokes,
        title => 'list'
    );

    $self->data_render('list');
}

#
#   Render from __DATA__ section.
#

sub data_render {
    my ( $self, $template ) = @_;

    my $DATA = Mojo::Command->new->get_all_data( __PACKAGE__ );
    
    $self->content_for(
        body => $self->render( inline => $DATA->{"$template.html.ep"} )
    );
    
    $self->render( inline => $DATA->{'base.html.ep'} );
}

sub update {
    my $self = shift;
    
    my $info = $self->read_joke( './lib/' . $self->param('plugin') );
    
    #   Make new config from params.
    #   Add dump of new config into data base.
    
    upd_conf( $info->{'config'} );
    

    # Insert if row does not exist.
    my @plugins = $self->data->read( plugins =>
        { id => $self->param('plugin') }
    );

    unless ( $#plugins ) {
        # Update and print "ok" or "cann't".
        $self->data->update( plugins =>
            # fields
            { config => freeze( $info->{'config'} ) },
            # where
            { id => $self->param('plugin') }
        );
    }
    else {
        $self->data->create( plugins =>
            {
                id => $self->param('plugin'),
                is_active => 0,
                config => freeze( $info->{'config'} )
            }
        );
    }
        
    $self->done('Plugin config updated!');
    
    #   Recursive make new config.
    
    sub upd_conf {
        my ( $conf, $parent ) = @_;
        
        $parent ||= '';
        
        for my $k ( keys %$conf ) {
            unless ( ref $conf->{$k} ) {
                # Perl rocks!
                $conf->{$k} = $self->param("$parent-$k-input");
            }
            else {
                upd_conf( $conf->{$k}, "$parent-$k" );
            }
        }
    }
}

sub turn {
    my $self = shift;

    my @plugins = $self->data->read (
        plugins => { id => $self->param('plugin') }
    );

    unless ( $#plugins ) {
        $self->data->update( plugins =>
            { is_active => 1 },
            { id => $self->param('plugin') }
        );
    }
    else {
        $self->data->create( plugins =>
            {
                id => $self->param('plugin'),
                is_active => 1
            }
        );
    }

    $self->done( 'Plugin is turning ' . $self->param('turn') );
}

sub scan {
    my $self = shift;
    
    #
    # Recursive get all files from $self->info('config')->{'scan_path'}.
    #
    
    my @dir = <$PLUG_PATH*>;
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
    my ( $self, $module ) = @_;
    
    # Get module name.
    $module = path2module($module);
    
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
    my $path = shift;
    
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
    color:#a00;
    font-family:"Times new roman";
    text-decoration: none;
}
a.off {
    font-weight:bold;
    color:#ccc;
    font-family:"Times new roman";
    text-decoration: none;
}
.changeable {
    border:1px solid #ddd;
    background:#fafafa;
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

@@ update.html.ep
% content_for body => begin
%= dumper $self->stash('config');
% end

@@ list.html.ep
% content_for body => begin
<div class="plugins">
<h2>Plugin list</h2>
%   my $jokes = $self->stash('jokes');
%   for my $plugin (values %$jokes) {
%       my ($stat, $do) = $plugin->{'is_active'} ? ('on','off') : ('off','on');
        <a href="<%= url_for('joker_read', plugin => $plugin->{'name'}) %>">
        <div class="plugin rounded">
            <%= $plugin->{'name'} %> (<%= $plugin->{'version'} %>)
            <div class="actions">
                <a class="action <%= $stat %>
                    rounded" href="<%= url_for('joker_turn',
                        plugin => $plugin->{'name'}, turn => $do) %>">J</a>
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
%       my ($stat, $do) = $plugin->{'is_active'} ? ('on','off') : ('off','on');
<div class="plugins">
    <h2><a class="on rounded action" href="<%= url_for('joker_list') %>">J</a> &rarr;
        <%= $plugin->{'name'} %></h2>
    <div class="actions">
        <a class="action <%= $stat %> rounded" href="
        %= url_for('joker_turn', plugin => $plugin->{'name'}, turn => $do)
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

=head1 Data Base Struct

=head2 Plugin table

    UNIC varchar| Binary    | BLOB
    id          | is_active | config

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

