package Mojolicious::Plugin::Joker;
use Mojo::Base 'Mojolicious::Plugin';

use Storable 'thaw';
use Data::Dumper;

our $VERSION = '0.2';

has [ qw/plugins jokes/ ] => sub { {} };
has root => './lib/Mojolicious/Plugin/';
has 'app';

# Will run once.
sub register {
    my ( $self, $app ) = @_;
    
    $self->app($app);
    
    $app->helper ( joker => sub { $self } );
    
    # core core plugins.
    my @core = qw/Message Data User/;
    
    $app->plugin('message');
    $app->plugin('data');
    $app->plugin('i18n');
    
    my $session = $app->sessions;
    $app->plugin( 'user' => { id => $session->{'user_id'} } );
    
    # Joker's routes.
    my $route = $app->routes;
    $route->namespace('Mojolicious::Plugin::Joker::Controller');
    
    # Check access
    my $r = $route->bridge('/joker')->to( cb => sub { $app->user->is_admin } );
    
    # List of plugins, which I found in ./lib/Mojolicious/Plugin.
    $r->route('/')->to('joker#list')->name('joker_list');
    
    # Plugin's CRUD
    # =============
    # To "create" plugin, you need move it in plugin's directory.
    # To "delete" it, you need remove its file form plugin's directory,
    # but it does not purge configuration.
    
    # Read. Show plugin's info.
    $r->route('/:plugin')->via('get')->to('joker#read')->name('joker_read');
    # Update. Only config is changable in plugin's info.
    $r->route('/:plugin')->via('post')->to('joker#update')->name('joker_update');
    # Also you can turn it on or off... after restart application.
    $r->route('/toggle/:plugin')->to('joker#toggle')->name('joker_toggle');

    # Plugins.
    my @plugins = $app->data->read('plugins');
    
    # Change state.
    map {
        # Annul change-bit.
        $_->{'state'} &= 0b011;
        # Invert active-bit if invert-bit is 1.
        $_->{'state'} ^= 0b011 if $_->{'state'} & 0b010;
    } @plugins;
    
    for my $p ( @core ) {
        $_->{'name'} eq $p and $_->{'state'} = 0b001 for @plugins;
    }
    
    $app->data->update(
        plugins => { state => $_->{'state'} }, { name => $_->{'name'} }
    ) for @plugins;

    # Load active plugins.
    @plugins = grep { $_->{'state'} == 0b001 } @plugins;
    
    # Save plugins' info.
    for my $plugin ( @plugins ) {
        $self->add( $self->read($plugin->{'name'}) );
        $self->add( $plugin );
    }
    
    # Exclude core modules.
    my %set;
    ++$set{ lc $_->{'name'} } for @plugins;
    delete $set{ lc $_ } for @core;
    @plugins = keys %set;
    
    $app->plugin( $_ ) for @plugins;
    
	#
	#   Helpers.
	#
	
    $app->helper (
    	# Recursive build html tables for config structure.
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
    
    $app->helper (
        is => sub {
            my ($self, $type, $val) = @_;

            if  ( $type eq 'mail' ) {
                return 1 if $val =~ m/^[a-z0-9_\-.]+@[a-z0-9_\-.]+$/i;
            }

            return 0;
        }
    );
    
    $app->helper (
        IS => sub {
            my ($self, $type, $val) = @_;
            $self->error( "It's not $type!" ) unless $self->is($type, $val);
        }
    );
}

sub add {
    my ( $self, $info ) = @_;
    
    if ( defined $info->{'name'} ) {
        $self->jokes->{ $info->{'name'} } = $info;
        $self->jokes->{ $info->{'name'} }->{'config'} = thaw $info->{'config'} if length $info->{'config'};
    }
}

sub scan {
    my $self = shift;
    my $root = $self->root;
    
    # Recursive get all files from ROOT.
    my @dir = <$root*>;
    my @files;
    
    while( @dir ) {
        my $path = pop @dir;
        # if file
        push @files, $path   if -r $path;
        # if directory
        push @dir, <$path/*> if -d $path;
    }
    
    my %ret;
    
    for my $f ( @files ) {
        my $pkg  = $self->path2module($f);
        my $info = $self->read($pkg);
        %ret = (%ret, $info->{'name'}, $info) if defined $info->{'name'};
    }
    
    return %ret;
}

sub read {
    # Get path to module.
    my ( $self, $module ) = @_;
    
    return {} unless $module;
    
    # Dynamic load module.
    # I'll be in Mexico when they'll understand what I did.
    use lib $module;
    
    my $obj = bless {}, $module;
    
    my $info = {
        'version' => $obj->version,
        'about'   => $obj->about,
        'depends' => $obj->depends,
        'config'  => $obj->config
    } if $obj->can('joke');
    
    no lib $module;
    
    $module =~ s/^Mojolicious::Plugin:://;
    
    # Info can be not defined...
    if( defined $info ) {
        $info->{'name'} = $module;
        return $info;
    }
    
    return {};
}

sub path2module {
    my ( $self, $path ) = @_;
    
    my @waypoints = split /[\\\/]/, $path;
    $waypoints[-1] =~ s/\.pm$//i;
    
    # Remove "./lib/" from path.
    return join('::', @waypoints[2..$#waypoints]);
}

1;

package Mojolicious::Plugin::Joker::Controller::Joker;
use Mojo::Base 'Mojolicious::Controller';

use Storable qw/freeze thaw/;

sub read {
    my $self = shift;
    
    # Read joke by file path.
    my $info = $self->joker->read( "Mojolicious::Plugin::" . $self->param('plugin') );
    return $self->error('Wrong plugin!') unless %$info;
    
    # Get plugin's info form db by ID.
    my $plugin = [
        $self->data->read( plugins => { name => $self->param('plugin') } )
    ]->[0];
    
    $info->{'state'} = $plugin->{'state'};
    # Replace default config if it's defined in db.
    $info->{'config'} = thaw $plugin->{'config'} if length $plugin->{'config'};
    
    $self->stash(
        jokes => $info,
        title => $info->{'name'}
    );

    $self->render;
}

#
#   List of plugins.
#

sub list {
    my $self = shift;
    
    my %jokes = $self->joker->scan;
    
    # Get config form database and push config to joke if joke exists.
    # $self->data->read('plugins') returns array of hashes.
    for my $plugin ( $self->data->read('plugins') ) {
        if( exists $jokes{ $plugin->{'name'} } ) {
            $jokes{ $plugin->{'name'} }->{'state'} = $plugin->{'state'};
            $jokes{ $plugin->{'name'} }->{'config'} = thaw $plugin->{'config'}
                if length $plugin->{'config'};
        }
    }
    
    $self->stash(
        jokes => \%jokes,
        title => 'list'
    );

    $self->render;
}

sub update {
    # It's not updating running-config (just startup-config).
    my $self = shift;
    
    my $info = $self->joker->read( "Mojolicious::Plugin::" . $self->param('plugin') );
    
    # Make new config from params.
    # Add dump of new config into data base.
    upd_conf( $self, $info->{'config'} );
    
    # Insert if row does not exist.
    my @plugins = $self->data->read (
        plugins => { name => $self->param('plugin') }
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
            { name => $self->param('plugin') }
        );
    }
    else {
        $self->data->create( plugins =>
            {
                name    => $self->param('plugin'),
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
        plugins => { name => $self->param('plugin') }
    );

    unless ( $#plugins ) {
        # Change invert-bit.
        my $new_state = $plugins[0]->{'state'} ^ 0b010;
        
        $self->data->update( plugins =>
            { state => $new_state },
            { name => $self->param('plugin') }
        );
    }
    else {
        $self->data->create( plugins =>
            {
                name    => $self->param('plugin'),
                state   => 0b010
            }
        );
    }

    $self->redirect_to( 'joker_read', plugin => $self->param('plugin') );
}

1;

__END__

=head1 Data Base Struct

=head2 Plugin table

    UNIC varchar 255 | Decimal 1 | Tiny BLOB
    name             | state(0)  | config

=head3 For MySQL

    CREATE TABLE IF NOT EXISTS `joke__plugins` (
      `name` varchar(11) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
      `state` int(2) NOT NULL,
      `config` tinytext NOT NULL,
      UNIQUE KEY `id` (`name`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8;

    state: change-bit | invert-bit | active-bit
    1 - if currently working;
    +2 - if invert working bit on restart;
    +4 - if configuration changed.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

