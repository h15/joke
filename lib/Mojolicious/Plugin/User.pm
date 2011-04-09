use strict;
use warnings;

use Digest::MD5 "md5_hex";

package Mojolicious::Plugin::User;

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
            my ($self, $action) = @_;
            
            return $obj unless defined $action;
            
            my $session = $app->sessions;
            my $id = $session->{'user_id'};
            # Anonymous has 1st id.
            $id ||= 1;
            
            $obj = new Mojolicious::Plugin::User::User (
                $self->data->read( users => { id => $id } )
            );
            
            return $obj;
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
    return 1 if $self->{'ban_reason'} == 0;
    return 0;
}

sub is_admin {
    my $self = shift;
    
    # In soviet Russia^W^W phpbb3 it's true.
    return 1 if grep { $_ == 3 } split ';', $self->{'groups'};
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
    
    my $key = Digest::MD5::md5_hex(rand);
    
    my @users = $self->data->read( users => {mail => $self->param('mail')} );
    
    unless ( $#users ) {
        $self->redirect_to('users_create_form');
        return;
    }
    
    #
    #   TODO: Send mail
    #
    
    $self->data->create( users => {
        mail    => $self->param('mail'),
        regdate => time,
        confirm_time => time + 60*60*24*7,
        confirm_key  => $key
    });
    
    $self->done('Check your mail.');
}

sub check_access {
    my $self = shift;
    
    $self->user('new');
    
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
	$self->session(	user_id  => '' )->redirect_to('index');
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

=head1 Data Base Struct

=head2 User table

    id              int 11                  (++)
    groups          tinytext                (empty)
    name            varchar 32  utf8-bin    (anonymous)
    mail            varchar 64  ascii-bin
    regdate         int 11                  (NOW on create)
    password        varchar 32              (0)
    ban_reason      int 2                   (0)
    ban_time        int 11                  (0)
    confirm_key     varchar 32              (generate on create)
    confirm_time    int 11                  (NOW on create)

=head3 For MySQL

    CREATE TABLE `joker`.`joke__users` (
        `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT ,
        `groups` TINYTEXT NOT NULL ,
        `name` VARCHAR( 32 ) CHARACTER SET utf8 COLLATE utf8_bin NULL ,
        `mail` VARCHAR( 64 ) CHARACTER SET ascii COLLATE ascii_bin NOT NULL ,
        `regdate` INT( 11 ) UNSIGNED NOT NULL ,
        `password` VARCHAR( 32 ) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '0',
        `ban_reason` INT( 2 ) UNSIGNED NOT NULL DEFAULT '0',
        `ban_time` INT( 11 ) UNSIGNED NOT NULL DEFAULT '0',
        `confirm_key` VARCHAR( 32 ) CHARACTER SET ascii COLLATE ascii_bin NOT NULL ,
        `confirm_time` INT( 11 ) UNSIGNED NOT NULL ,
        PRIMARY KEY ( `id` ) ,
        INDEX ( `id` ) ,
        UNIQUE (
            `name` ,
            `mail`
        )
    ) ENGINE = MYISAM ;
    
    INSERT INTO `joke__users` (`id`, `groups`, `name`, `mail`, `regdate`, `password`, `ban_reason`, `ban_time`, `confirm_key`, `confirm_time`) VALUES(1, '', 'anonymous', 'anonymous@lorcode.org', 0, '0', 0, 0, '', 0);

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

