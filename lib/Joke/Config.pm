package Joke::Config;
use Joke::Base -base;

use Storable qw(freeze thaw);

has configs => sub { {} };
has config  => undef;

sub init {
    my $self = shift;
    
    {
        local $/;
        open F, './lib/Joke/config.dat' or die '[-] Can\'t read config.dat';
        my $a = <F>;
        close F;
        $self->configs( thaw $a );
    }
    
    my $r = $self->app->routes->to( namespace => 'Joke::Config::Controller' );
    my $a = $r->bridge('/admin/config')->to( cb => sub { shift->user->is_admin } );
       $a->route('/')->via('get')->to('config#list')->name('config_list');
    
    $self->app->helper( config => sub { $self } );
}

# Recursive build html tables for config structure.
sub render {
    my ( $self, $config, $parent ) = @_;

    my $ret   = '';
    $parent ||= '';
    $config ||= {};
    
    for my $k ( keys %$config ) {
        $ret .= "<tr><td>$k</td><td name='$parent-$k'>";
        
        # Branch or leaf?
        $ret .= ( ref $config->{$k} ?
            $self->render( $config->{$k}, "$parent-$k" ) :
            "<input value='" . $config->{$k} . "' name='$parent-$k-input'>"
        );
        $ret .= "</td></tr>";
    }
    return "<table>$ret</table>";
}

sub _get { shift->configs->{shift} }

sub _set {
    my ( $self, $k, $v ) = @_;
    
    %{$self->configs} = ( %{$self->configs}, $k, $v );
}

sub save {
    my $self = shift;
   
    {
        local $/;
        open  F, '>./lib/Joke/config.dat' or die '[-] Can\'t write into config.dat';
        print F freeze $self->configs;
        close F;
    }
}

1;

__END__ 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

