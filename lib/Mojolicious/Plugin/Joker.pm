package Mojolicious::Plugin::Joker;
use Mojo::Base 'Mojolicious::Plugin';

use Storable 'thaw';
use Mojo::ByteStream;

our $VERSION = 0.2;

has jokes => sub { {} };
has core  => sub { [qw/I18n Message Data User Captcha/] };
has root  => './lib/Mojolicious/Plugin/';
has 'app';

# Will run once.
sub register {
    my ( $self, $app ) = @_;
    
    # Some init
    $self->app($app);
    $app->helper( joker => sub { $self } );
    $app->plugin( lc $_ ) for @{$self->core};
    
    # Routes
    my $route = $app->routes->namespace('Mojolicious::Plugin::Joker::Controller');
    my $r = $route->bridge('/joker')->to( cb => sub { $app->user->is_admin } );
    
    # List, Read, Update, Turn 
    $r->route('/')->to('joker#list')->name('joker_list');
    $r->route('/:joke')->via('get')->to('joker#read')->name('joker_read');
    $r->route('/:joke')->via('post')->to('joker#update')->name('joker_update');
    $r->route('/toggle/:joke')->to('joker#toggle')->name('joker_toggle');
    
    $self->wake_up;
    
	# Helpers
    $app->helper (
    	# Recursive build html tables for config structure.
        html_hash_tree => sub {
            my ( $self, $config, $parent ) = @_;
            my $ret = '';
            $parent ||= '';
            
            for my $k ( keys %$config ) {
                $ret .= "<tr><td>$k</td><td name='$parent-$k'>";
                
                # Branch or leaf?
                $ret .= ( ref $config->{$k} ?
                    $self->html_hash_tree( $config->{$k}, "$parent-$k" ) :
                    "<input value='" . $config->{$k} . "' name='$parent-$k-input'>"
                );
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
    
    $app->helper (
        render_datetime => sub {
            my ($self, $val) = @_;
            
            my ( $s, $mi, $h, $d, $mo, $y ) = localtime;
            my ( $sec, $min, $hour, $day, $mon, $year ) = map { $_ < 10 ? "0$_" : $_ } localtime($val);
            
            # Pretty time.
            my $str = (
                $year == $y ?
                    $mon == $mo ?
                        $day == $d ?
                            $hour == $h ?
                                $min == $mi ?
                                    $sec == $s ?
                                        $self->l('now')
                                    :   $self->l('a few seconds ago')
                                :   ago( min => $mi - $min, $self )
                            :   ago( hour => $h - $hour, $self )
                        :   "$hour:$min, $day.$mon"
                    :   "$hour:$min, $day.$mon"
                :   "$hour:$min, $day.$mon." . ($year + 1900)
            );
            
            $year += 1900;
            
            return new Mojo::ByteStream ( qq[<time datetime="$year-$mon-${day}T$hour:$min:${sec}Z">$str</time>] );
            
            sub ago {
                my ( $type, $val, $self ) = @_;
                my $a = $val % 10;
                
                # Different word for 1; 2-4; 0, 5-9 (in Russian it's true).
                $a = (
                    $a != 1 ?
                        $a > 4 ?
                            5
                        :   2
                    :   1
                );
                
                return $val ." ". $self->l("${type}s$a") ." ". $self->l('ago');
            }
        }
    );
}

sub wake_up {
    my ( $self ) = @_;
    
    # Read all joke's accounts from data base.
    my %jokes = map { $_->{name}, $_ } $self->app->data->list('jokes'); 
    
    # Change state.
    for ( keys %jokes ) {
        # Annul change-bit.
        $jokes{$_}->{state} &= 0b011;
        # Invert active-bit if invert-bit is 1.
        $jokes{$_}->{state} ^= 0b011 if $jokes{$_}->{state} & 0b010;
    }
    
    $self->app->data->update( jokes =>
        { state => $jokes{$_}->{state} },
        { name => $_ }
    ) for keys %jokes;
    
    # Load only active or core jokes.
    $jokes{$_}->{state} = 0b001 for @{$self->core};
    
    for ( keys %jokes ) {
        delete $jokes{$_}, next if $jokes{$_}->{state} != 0b001;
        
        $self->jokes->{$_} = $self->read($_);
        $self->jokes->{$_}->{config} = thaw $jokes{$_}->{config} if defined $jokes{$_}->{config} && length $jokes{$_}->{config};
        $self->jokes->{$_}->{config} ||= {};
    }
    
    # Joke, repeated twice, doubly funny. But...
    delete $jokes{$_} for @{$self->core};
    $self->app->plugin( lc $_ ) for keys %jokes;
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
        my $info = $self->read( $self->path2module($f) );
        %ret = (%ret, $info->{name}, $info) if defined $info->{name};
    }
    
    return %ret;
}

sub read {
    my ( $self, $module ) = @_;
    
    return {} unless $module;
    
    # Dynamic load module.
    eval "require $module";
    my $obj = bless {}, $module;
    my $info = $obj->joke( $self->app ) if $obj->can('joke') ;
    eval "no $module";
    
    # Info can be not defined...
    if ( defined $info->{version} ) {
        $module =~ s/^Mojolicious::Plugin:://;
        $info->{name} = $module;
        $info->{state} ||= 0;
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
    
    my $info = $self->joker->read( "Mojolicious::Plugin::" . $self->param('joke') );
    return $self->error('Wrong joke!') unless %$info;
    
    # Get joke's info form db by NAME.
    my $joke = $self->data->read_one( jokes => { name => $self->param('joke') } );
    
    $info->{state} = $joke->{state} if defined $joke->{state};
    $info->{config} = thaw $joke->{config} if length $joke->{config};
    
    $self->stash (
        joke => $info,
        title => $info->{name}
    );

    $self->render;
}

sub list {
    my $self = shift;
    
    my %jokes = $self->joker->scan;
    
    # State, config from db.
    for my $joke ( $self->data->list('jokes') ) {
        if( exists $jokes{ $joke->{name} } ) {
            $jokes{ $joke->{name} }->{state} = $joke->{state};
            $jokes{ $joke->{name} }->{config} = thaw $joke->{config} if length $joke->{config};
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
    
    my $info = $self->joker->read( "Mojolicious::Plugin::" . $self->param('joke') );
    
    # Get new config.
    upd_conf( $self, $info->{config} );
    
    # Insert if row does not exist.
    my $joke = $self->data->read_one( jokes => { name => $self->param('joke') } );
    
    if ( defined %$joke ) {
        $self->data->update( jokes =>
            {
                config  => freeze($info->{config}),
                state   => $joke->{state} | 0b100
            },
            {   name    => $self->param('joke') }
        );
    }
    else {
        $self->data->create( jokes => {
            name    => $self->param('joke'),
            state   => 0b100,
            config  => freeze $info->{config}
        });
    }
        
    $self->redirect_to( 'joker_read', joke => $self->param('joke') );
    
    # Recursive make new config.
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

    my $joke = $self->data->read_one( jokes => { name => $self->param('joke') } );

    if ( defined %$joke ) {
        # Change invert-bit.
        my $new_state = $joke->{state} ^ 0b010;
        
        $self->data->update( jokes =>
            { state => $new_state },
            { name => $self->param('joke') }
        );
    }
    else {
        $self->data->create( jokes => {
            name  => $self->param('joke'),
            state => 0b010
        });
    }

    $self->redirect_to( 'joker_read', joke => $self->param('joke') );
}

1;

__END__

=head1 Controllers

=item /joker

You can read it and subdirectories if you in admins group.

=item /

List of jokes, which Joker found in ./lib/Mojolicious/joke.

=item /:joke

Read on get and Update on post.

=item /toggle/:joke

Turn off/on.

=head2 Create and Delete

To "create" joke, you should move it in joke's directory.
To "delete" it, you should remove its file form joke's directory, but it does
not purge configuration.

=head1 Data Base Struct

=head2 joke table

    UNIC varchar 255 | Decimal 1 | Tiny BLOB
    name             | state(0)  | config

=head3 For MySQL

    CREATE TABLE IF NOT EXISTS `joke__jokes` (
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

