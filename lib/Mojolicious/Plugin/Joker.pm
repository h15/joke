use strict;
use warnings;

package Mojolicious::Plugin::Controller::Joker;
use Storable qw/freeze thaw/;

use base 'Mojolicious::Controller';

our $ROOT = './lib/Mojolicious/Plugin/';

sub read {
    my $self = shift;
    
    my $path = $self->param('plugin');
    $path =~ s/::/\//g;
    $path = "$ROOT$path.pm";
    
    # If module's file does not exist.
    return $self->error("Cann't read file $path!") unless -r $path;
    
    # Read joke by file path.
    my $info = $self->read_joke( $path );
    
    # If module has not info.
    return $self->error("$path doesn't have info.") unless $info;
    
    # Get plugin's info form db by ID.
    my $plugin = [
        $self->data->read( plugins => { id => $self->param('plugin') } )
    ]->[0];
    
    $info->{'state'} = $plugin->{'state'};
    # Replace default config if it's defined in db.
    $info->{'config'} = thaw $plugin->{'config'} if length $plugin->{'config'};
    
    $self->stash(
        jokes => $info,
        title => $info->{'name'}
    );

    $self->render_data_section('read');
}

#
#   List of plugins.
#

sub list {
    my $self = shift;
    
    my %jokes = $self->scan;
    
    # Get config form database and push config to joke if joke exists.
    # $self->data->read('plugins') returns array of hashes.
    
    for my $plugin ( $self->data->read('plugins') ) {
        if( exists $jokes{ $plugin->{'id'} } ) {
            $jokes{ $plugin->{'id'} }->{'state'} = $plugin->{'state'};
            $jokes{ $plugin->{'id'} }->{'config'} = thaw $plugin->{'config'}
                if length $plugin->{'config'};
        }
    }
    
    $self->stash(
        jokes => \%jokes,
        title => 'list'
    );

    $self->render_data_section('list');
}

sub update {
    # It's not updating running-config (just startup-config).
    my $self = shift;
    
    my $info = $self->read_joke( $ROOT . $self->param('plugin') );
    
    # Make new config from params.
    # Add dump of new config into data base.
    
    upd_conf( $self, $info->{'config'} );
    
    # Insert if row does not exist.
    my @plugins = $self->data->read (
        plugins => { id => $self->param('plugin') }
    );

    unless ( $#plugins ) {
        # Update and print "ok" or "cann't".
        $self->data->update( plugins =>
            # fields
            {
                config  => freeze( $info->{'config'} ),
                state   => $plugins[0]->{'state'} | 0b100
            },
            # where
            { id => $self->param('plugin') }
        );
    }
    else {
        $self->data->create( plugins =>
            {
                id      => $self->param('plugin'),
                state   => 0b100,
                config  => freeze( $info->{'config'} )
            }
        );
    }
        
    $self->redirect_to( 'joker_read', plugin => $self->param('plugin') );
    
    #   Recursive make new config.
    
    sub upd_conf {
        my ( $self, $conf, $parent ) = @_;
        
        $parent ||= '';
        
        for my $k ( keys %$conf ) {
            unless ( ref $conf->{$k} ) {
                # Perl rocks!
                $conf->{$k} = $self->param("$parent-$k-input");
            }
            else {
                upd_conf( $self, $conf->{$k}, "$parent-$k" );
            }
        }
    }
}

sub toggle {
    my $self = shift;

    my @plugins = $self->data->read (
        plugins => { id => $self->param('plugin') }
    );

    unless ( $#plugins ) {
        # Change invert-bit.
        my $new_state = $plugins[0]->{'state'} ^ 0b010;
        
        $self->data->update( plugins =>
            { state => $new_state },
            { id => $self->param('plugin') }
        );
    }
    else {
        $self->data->create( plugins =>
            {
                id      => $self->param('plugin'),
                state   => 0b010
            }
        );
    }

    $self->redirect_to( 'joker_read', plugin => $self->param('plugin') );
}

sub scan {
    my $self = shift;
    
    # Recursive get all files from $ROOT.
    my @dir = <$ROOT*>;
    my @files;
    
    while( @dir ) {
        my $path = pop @dir;
        
        # if file
        push @files, $path   if -r $path;
        
        # if directory
        push @dir, <$path/*> if -d $path;
    }
    
    # Read all service information.
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
    
    return 0 unless $module;
    
    # Get module name.
    $module = path2module($module);
    
    # Check info.
    # Dynamic load module.
    use lib $module;
    
    my $obj = bless {}, $module;
    my $info = $obj->info if defined *{$module . '::info'};
    
    no lib $module;
    
    # Info can be not defined...
    if( defined $info ) {
        $info->{'name'} = substr $module, 2 + length path2module($ROOT);
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

package Mojolicious::Plugin::Joker;

use base 'Mojolicious::Plugin';
use Storable 'thaw';

our $VERSION = '0.2';

# Will run once.
sub register {
    my ( $self, $app ) = @_;
    
    my $session = $app->sessions;
    
    # Preload core plugins.
    my @preload_modules = qw/message data user/;
    $app->plugin('message');
    $app->plugin('data');
    $app->plugin( 'user' => { id => $session->{'user_id'} } );
    
    #
    #   Joker's routes.
    #
    
    my $r = $app->routes;
    $r->namespace('Mojolicious::Plugin::Controller');
    
    # List of plugins, which I found in ./lib/Mojolicious/Plugin.
    $r->route('/joker')->to('joker#list')->name('joker_list');
    
    # Plugin's CRUD
    # =============
    # To "create" plugin, you need move it in plugin's directory.
    # To "delete" it, you need remove its file form plugin's directory,
    # but it does not purge configuration.
    
    # Read. Show plugin's info.
    $r->route('/joker/:plugin')->via('get')->to('joker#read')->name('joker_read');
    
    # Update. Only config is changable in plugin's info.
	$r->route('/joker/:plugin')->via('post')->to('joker#update')->name('joker_update');
    
    # Also you can turn it on or off... after restart application.
    $r->route('/joker/toggle/:plugin')->to('joker#toggle')->name('joker_toggle');

    #
    #   Plugins.
    #
    
    my @plugins = $app->data->read('plugins');
    
    # Change state.
    map {
        # Annul change-bit.
        $_->{'state'} &= 0b011;
        # Invert active-bit if invert-bit is 1.
        $_->{'state'} ^= 0b011 if $_->{'state'} & 0b010;
    } @plugins;
    
    $app->data->update(
        plugins => { state => $_->{'state'} }, { id => $_->{'id'} }
    ) for @plugins;
    
    # Load active plugins.
    @plugins = grep { $_->{'state'} == 0b001 } @plugins;
    
    # Exclude preload modules.
    my %set;
    ++$set{$_}      for @plugins;
    delete $set{$_} for @preload_modules;
    @plugins = keys %set;
    
    $app->plugin( lc $_->{'id'} ) for @plugins;
    
	#
	#   Helpers.
	#
	
    $app->helper (
    	# Recursive build html tables for config structure.
    	# FIXME: it's dirty.
        html_hash_tree => sub {
            my ( $self, $config, $parent ) = @_;
            my $ret;
            $parent ||= '';
            
            for my $k ( keys %$config ) {
                $ret .= "<tr><td>$k</td><td name='$parent-$k'>";
                
                # Branch or leaf?
                $ret .= ref $config->{$k} ?
                    $self->html_hash_tree( $config->{$k}, "$parent-$k" ) :
                    "<input value='" . $config->{$k} . "' name='$parent-$k-input'>";
                
                $ret .= "</td></tr>";
            }

            return "<table>$ret</table>";
        }
    );
    
    $app->helper(
        # Render from __DATA__ section.
        render_data_section => sub {
            my ( $self, $package, $template ) = @_;
            
            unless ( defined $template ) {
                $template = $package;
                $package = __PACKAGE__;
            }

            my $DATA = Mojo::Command->new->get_all_data( __PACKAGE__ );
            
            my $BODY = $package ne __PACKAGE__ ? 
                Mojo::Command->new->get_all_data( $package ) : $DATA;
            
            $self->content_for (
                body => $self->render( inline => $BODY->{"$template.html.ep"} )
            );
            
            $self->render( inline => $DATA->{'base.html.ep'} );
        }
    );
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
	width:600px;
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
.info {
    padding: 5px 5px 5px 15px;
    margin: 0px 0px 10px 10px;
	background: #ffd;
	border: 1px solid #fff7dd;
	-moz-border-radius: 4px;
	-webkit-border-radius: 4px;
	border-radius: 4px;
	-khtml-border-radius: 4px;
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
    font-family: Sans-Serif,'Lucida Grande';
    font-size: 14px;
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
a.action:hover {
    background-color:#ddd;
}
.action {
    float:left;
    display:inline;
    padding:5px 10px 5px 10px;
    margin:-6px 0px 0px 10px;
}
.plugins {
    margin:0px auto;
    width:600px;
}
.plugins h2 {
    color:#ccc;
}
.on, a.on {
    font-weight:bold;
    color:#a00;
    font-family:"Times new roman";
    text-decoration: none;
    display:inline;
}
.off, a.off {
    font-weight:bold;
    color:#ccc;
    font-family:"Times new roman";
    text-decoration: none;
    display:inline;
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
%       my $active = $plugin->{'state'} & 0b001;
%       my $invert = $plugin->{'state'} & 0b010;
%       my $change = $plugin->{'state'} & 0b100;
%
        <div class="plugin rounded">
            <a href="<%= url_for('joker_read', plugin => $plugin->{'name'}) %>">
                <%= $plugin->{'name'} %></a> (<%= $plugin->{'version'} %>)
            <div class="actions">
% if ( $invert ) {
                <div class="rounded action">
                    <span class="<%= $active ? 'on' : 'off' %>">J</span> &rarr;
                    <span class="<%= $active ? 'off' : 'on' %>">J</span>
                </div>
% }
% if ( $change ) {
                <div class="rounded on action">*</div> &nbsp;
% }
                <div class="action 
%= $active ? 'on' : 'off';
                    rounded" href="<%= url_for('joker_toggle', plugin => $plugin->{'name'}) %>">J</div>
            </div>
        </div>
%   }
</div>
<!-- End of body 
% end

@@ read.html.ep
% content_for body => begin
% my $plugin = $self->stash('jokes');
%
% my $active = $plugin->{'state'} & 0b001;
% my $invert = $plugin->{'state'} & 0b010;
% my $change = $plugin->{'state'} & 0b100;
%
<div class="plugins">
    <h2><a class="on rounded action" href="<%= url_for('joker_list') %>">J</a>&nbsp;&rarr;
        <%= $plugin->{'name'} %></h2>
%#
%#          Show notifications
%#
% if ( $invert ) {
    <div class="info">
        Joke should be restarted to turn it <%= $active ? 'off' : 'on' %>.
    </div>
% }
% if ( $change ) {
    <div class="info">
        Joke should be restarted to apply changes.
    </div>
% }
    <div class="actions">
        <div class="action <%= $active ? 'on' : 'off' %> rounded">J</div>
    </div>
%#
%#          PLUGIN's INFO
%#
<div class="plugins rounded">
    <table class="simple_table">
        <tr>
            <td>about</td>
            <td><%= $plugin->{'about'} %>
                <a href=<%= url_for('joker_toggle', plugin => $plugin->{'name'}) %>>
                    Turn it <%= ($active xor $invert) ? 'off' : 'on' %>
                </a>
            </td>
        </tr>
        <tr>
            <td>version</td>
            <td><%= $plugin->{'version'} %></td>
        </tr>
        <tr>
            <td>depends</td>
            <td>
%#
%#          LIST OF DEPS
%#
% for my $dep ( @{$plugin->{'depends'}} ) {
    <a href="<%= url_for('joker_read', plugin => $dep)%>"><%= $dep %></a>&nbsp;
% }
            </td>
        </tr>
        <tr>
            <td>config</td>
            <td>
% if ( keys %{$plugin->{'config'}} ) {
<form action="<%= url_for('joker_update', plugin => $plugin->{'name'}) %>"
    method=POST>
%== html_hash_tree( $plugin->{'config'} );
    <input type="submit" class="alignright">
</form>
% }
% else {
    empty
% }
            </td>
        </tr>
        <tr>
            <td>author</td>
            <td><%= $plugin->{'author'} %></td>
        </tr>
    </table>
</div>
</div>
<!-- End of body 
% end

__END__

=head1 Data Base Struct

=head2 Plugin table

    UNIC varchar 255 | Decimal 1 | Tiny BLOB
    id               | state(0)  | config
    
    state: change-bit | invert-bit | active-bit
    1 - if currently working;
    +2 - if invert working bit on restart;
    +4 - if configuration changed.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

