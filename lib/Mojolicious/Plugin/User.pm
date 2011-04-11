use strict;
use warnings;

use Digest::MD5 "md5_hex";
use MIME::Base64;
use Mojolicious::Plugin::User::User;

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
            cookies => 'some random string',
            confirm => 7
        }
    };
    
    return $info->{$field} if $field;
    return $info;
}

sub register {
    my ( $self, $app ) = @_;
    
    $app->secret( $self->info('config')->{'cookies'} );
    $app->sessions->default_expiration(3600*24*7);
    
    # Shared object.
    my $obj;
    
    # Run on any request!
    $app->hook( before_dispatch => sub {
        my $self = shift;
        
        my $session = $app->sessions;
        my $id = $session->{'user_id'};
        # Anonymous has 1st id.
        $id ||= 1;
        
        $obj = new Mojolicious::Plugin::User::User (
            $self->data->read( users => { id => $id } )
        );
    });
    
    $app->helper (
        user => sub {
            return $obj;
        }
    );
    
    # Routes
    my $route = $app->routes;
    $route->namespace('Mojolicious::Plugin::Controller');
    my $r = $route->bridge('/user')->to('auths#check_access');
    
    # User (CRUD+L)
    $route->route('/user/new')->via('get')->to('users#form')->name('users_form');
    $route->route('/user/:id' , id => qr/\d+/)->via('get')->to('users#read')->name('users_read');
    $route->route('/users/:id', id => qr/\d*/)->via('get')->to('users#list')->name('users_list');
    $r->route('/new')->via('post')->to('users#create')->name('users_create');
    $r->route('/:id', id => qr/\d+/)->via('put')->to('users#update')->name('users_update');
    $r->route('/:id', id => qr/\d+/)->via('delete')->to('users#delete')->name('users_delete');
    
    # Auth (Action)
    $r->route('/login')->via('post')->to('auths#login')->name('auths_login');
    $r->route('/logout')->to('auths#logout')->name('auths_logout');
    $route->route('/user/login')->via('get')->to( cb => sub {
        shift->render( template => 'auths/login_form' )
    } )->name('auths_login_form');
    # Login by mail:
    $route->route('/user/login/mail')->via('get')->to( cb => sub {
        shift->render( template => 'auths/login_mail_form' )
    } )->name('auths_login_mail_form');
    $route->route('/user/login/mail')->via('post')->to('auths#login_mail_request')->name('auths_login_mail_request');
    $route->route('/user/login/mail/confirm')->to('auths#login_mail')->name('auths_login_mail');
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

