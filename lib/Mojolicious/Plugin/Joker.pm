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
    
    $r->route('/joker')->to('joker#list')->name('joker_list');
    
    $r->route('/joker/:plugin', plugin => qr/^[a-zA-Z0-9_\-]+$/)->via('get')
        ->to('joker#read')->name('joker_read');
	
	#
	#   Load active plugins.
	#
	
	
}

package Mojolicious::Plugin::Controller::Joker;

use base 'Mojolicious::Controller';

# cRud
sub read {
    my $self = shift;
    
    my $path = $self->param('plugin');
    $path =~ s/::/\//g;
    
    # Read joke by file path.
    my $info = $self->read_joke( $self->info('config')->{'scan_path'} . $path );
    
    # Add joke to stash
    $self->stash('jokes')->{ $info->{'name'} } = $info;
    
    my @plugins = $self->data->read( plugins => {
        name => $self->param('plugin')
    });
    
    # Add config info from db if joke exists
    if( exists $self->stash('jokes')->{ $plugins[0]->{'name'} } ) {
        $self->stash('jokes')
            ->{ $plugins[0]->{'name'} }->{'config'} = $plugins[0];
    }
    
    $self->render( template => 'mojolicious/plugin/joker/read.html.ep' );
}

#
#   List of plugins.
#

sub list {
    my $self = shift;
    
    #
    #   Get config form database and push config to joke if joke exists.
    #   $self->data->read('plugins') returns array of hashes.
    #
    
    for my $plugin ( $self->data->read('plugins') ) {
        if( exists $self->stash('jokes')->{ $plugin->{'name'} } ) {
            $self->stash('jokes')->{ $plugin->{'name'} }->{'config'} = $plugin;
        }
    }
    
    $self->render( template => 'mojolicious/plugin/joker/list.html.ep' );
}

sub scan {
    my ($self, $scan_path) = @_;
    
    #
    #   Recursive get all files from $self->info('config')->{'scan_path'}.
    #
    
    $scan_path ||= $self->info('config')->{'scan_path'};
    
    my @dir = <"$scan_path*">;
    my @files;
    
    while( @dir ) {
        my $path = pop @dir;

        # if file
        push @files, $path   if -f $path;
        
        # if directory
        push @dir, <$path/*> if -d $path;
    }
    
    #
    #   Read all service information.
    #   $self->stash('jokes') will have hash (joke's name is a key)
    #   of hashes (info).
    #
    
    for my $joke ( @files ) {
        my $info = $self->read_joke($joke);
        
        #   Don't read jokes without info.
        next unless $info;
        
        $self->stash('jokes')->{ $info->{'name'} } = $info;
    }
}

#
#   Read module's params such as version, author, conditions.
#

sub read_joke {
    # Get path to module.
    my ($self, $module) = @_;
    
    # Get module name.
    $module = $self->path2module($module);
    
    Mojo::Loader->load($module);
    
    # Here should be all needed info.
    my $info = $module->info();
    Mojo::Loader->_unload($module);
    
    return $info;
}

sub path2module {
    my ($self, $path) = @_;
    
    my @waypoints = split /[\\\/]/, $path;
    $waypoints[-1] =~ s/\.pm$//i;
    
    return join('::', @waypoints);
}

1;

__DATA__
@@ mojolicious/plugin/joker/base.html.ep
<!doctype html>
<html>
    <head>
        <%= content_for 'header' %>
        <title>Joker plugin system &rarr; <%= content_for 'title' %></title>
    </head>
    <body>
        <%= content_for 'body' %>
    </body>
</html>

@@ mojolicious/plugin/joker/list.html.ep
% extends 'mojolicious/plugin/joker/base.html.ep';
<% content_for header => begin %>
    list
<% end %>
<% content_for header => begin %>
%   for my $plugin (@$plugins) {
        <div class="plugin">
            <%= $plugin->{'name'} %> (<%= $plugin->{'version'} %>)
            <div class="actions">
                <a class="action config"
                    href="<%= url_for('joker_read',
                        plugin => $plugin->{'name'}) %>">*</a>
%               if( $plugin->{'active'} ) {
                    <a class="action on"
                        href="<%= url_for('joker_update',
                            plugin => $plugin->{'name'}, do => 'on') %>">on</a>
%               }
%               else {
                    <a class="action off"
                       href="<%= url_for('joker_update',
                          plugin => $plugin->{'name'}, do => 'off') %>">off</a>
%               }
                <a class="action copyright"
                   href="<%= url_for('joker_read',
                     plugin => $plugin->{'name'}, do => 'about') %>">&copy;</a>
            </div>
        </div>
%   }
<% end %>



__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

