package Mojolicious::Plugin::User;

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
        about   => 'Plugin for Users system.',
        fields  => {
        # Needed fields.
        },
        depends => [ qw/Data Message Mail/ ],
        config  => {
        # May be should init admin here?
            cookies => 'some random string'
        }
    };
    
    return $info->{$field} if $field;
    return $info;
}

sub register {
    my ( $self, $app ) = @_;
    
    $app->secret( $self->info('config')->{'cookies'} );
    $app->sessions->default_expiration(3600*24*7);
    
    # Routes
    my $route = $app->routes;
    my $r = $route->bridge('/user')->to('users#check_access');
    
    # CRUD for User.
    $r->route('/new')->via('get')->to('users#create_form')->name('users_create_form');
    $r->route('/new')->via('post')->to('users#create')->name('users_create');
    $r->route('/:id', id => qr/\d+/)->via('post')->to('users#read')->name('users_read');
    $r->route('/:id', id => qr/\d+/)->via('put')->to('users#update')->name('users_update');
    $r->route('/:id', id => qr/\d+/)->via('delete')->to('users#delete')->name('users_delete');
    # +List
    $r->route('/list/:id', id => qr/\d+/)->via('get')->to('users#create')->name('users_list');
    
    # Auth
    $r->route('/login')->via('get')->to('users#login_form')->name('users_login_form');
    $r->route('/login')->via('post')->to('users#login')->name('users_login');
    $r->route('/logout')->to('users#logout')->name('users_logout');
    
    # Shared object.
    my $obj;
    
    $app->helper (
        user => sub {
            my ( $self, $new_obj ) = @_;
            
            if ( defined $new_obj ) {
                $obj = $new_obj;
            }
            
            return $obj;
        }
    );
    
    $app->helper (
        sess => sub {
            my $session = $app->sessions;
            return $session;
        }
    );
}

1;

package Mojolicious::Plugin::User::User;

sub new {
    my ( $self, @users ) = @_;
    
    return bless {}, $self if $#users;

    bless $users[0], $self;
}

sub is_active {
    my $self = shift;
    return 1 if $self->{'inactive_reason'} == 0;
    return 0;
}

sub is_admin {
    my $self = shift;
    
    # In soviet Russia^W^W phpbb3 it's true.
    return 1 if $self->{'role'} == 3;
    return 0;
}

1;

package Mojolicious::Plugin::Controller::Users;

use base 'Mojolicious::Controller';

sub read {
    my $self = shift;
    
	# Get accounts by id.
	my @users = $self->select( users => '*', { id => $self->stash('id') } );
    
    $self->error("User with this id doesn't exist!") if $#users;
    
    if( $self->user->{'id'} != 1                        # not Anonymous
        && $self->stash('id') == $self->user->{'id'}    # and Self
        || $self->user->is_admin() ) {                  # or  Admin.
        
        $self->read_extended(@users);
    }

    $self->stash( user => $users[0] );

    $self->render;
}

sub read_extended {
    my $self = shift;
    my @users = @_;
    
    $self->render(
        action => 'read_extended',
    );
}

sub create_form {
    shift->render;
}

sub create {
    my $self = shift;
    
    my $key = 
    
    #
    #   Send mail
    #
    
    $self->data->create( users => {
        mail    => $self->param('mail'),
        regdate => time,
        confirm_time => time + 60*60*24*7,
        
    });
}

sub check_access {
    my $self = shift;
    
    my $id = $self->sess->{'user_id'};
    
    # Anonymous has 1st id.
    $id ||= 1;
    
    $self->user( new Mojolicious::Plugin::User::User (
        $self->data->read( users => { id => $id } )
    ) );
    
    #
    #   TODO: some easy acl.
    #
    
    return 1;
    if ( $self->user->is_admin ) {
        return 1;
    }
    
    $self->error('You have not access for this page!');
    return 0
}

sub login {
    #
    #   TODO: Login attempts counter for ip.
    #
    
	my $self = shift;
	
	# It's not an e-mail!
	$self->IS( mail => $self->param('mail')	);
	
	# Get accounts by e-mail.
	my @users = $self->select( users => '*', {email => $self->param('mail')} );
    
    # If this e-mail does not exist
    # or more than one account has this e-mail.
    $self->error("This pair(e-mail and password) doesn't exist!") if $#users;
    
    my $user = $users[0];
    
    # Password test:
    #   hash != md5( regdate + password + salt )
    my $s = $user->{'regdate'} . $self->param('passwd') . $self->stash('salt');
    
    if ( $user->{'password'} ne Digest::MD5::md5_hex($s) ) {
        $self->error( "This pair(e-mail and password) doesn't exist!" );
        
        # Don't work without return. I don't know why.
        return;
    }
    
    # Init session.
    $self->session (
        user_id  => $user->{'id'},
    )->redirect_to( 'user_read', id => $user->{'id'} );
}

sub logout {
    my $self = shift;
    
    # Delete session.
	$self->session(
		user_id  => '',
	)->redirect_to('index');
}

sub login_form {
    my $self = shift;
    
    #
    #   TODO: Login counter and CAPTCHA
    #
    $self->stash( title => 'Login' );
    $self->render_data_section(__PACKAGE__, 'login_form');
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

