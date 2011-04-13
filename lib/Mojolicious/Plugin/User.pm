package Mojolicious::Plugin::User;
use Mojo::Base 'Mojolicious::Plugin';

use Digest::MD5 "md5_hex";
use MIME::Base64;

use Mojolicious::Plugin::User::User;

has version => 0.2;
has about   => 'Plugin for Users system.';
has depends => sub { [ qw/Data Message Mail/ ] };
has config  => sub { { cookies => 'some random string', confirm => 7 } };

has joke => sub { 1 };

=head1 Plugin User

=head2 About

Use this plugin to enable ACL (access control list), authentification and CRUD
users. It used by Joke default.

=head2 Structure

    Mojolicious::Plugin
     `- User.pm                 # Routes, info, hook for running on each request
         |- User.pm             # User object
         `- Controller
             |- Auths.pm        # Login/out, by mail
             `- Users.pm        # CRUD+L

=head3 Mojolicious::Plugin::User

=over

=item register

Plugin's default method for init self on load. Register consists hook for reinit
on every dispatch (every request in our case).

=back

=cut

sub register {
    my ( $controller, $app ) = @_;
    my $self = new Mojolicious::Plugin::User;
    my $user = new Mojolicious::Plugin::User::User;
    
    $app->secret( $self->config->{'cookies'} );
    $app->sessions->default_expiration(3600*24*7);
    
    # Run on any request!
    $app->hook( before_dispatch => sub {
        my $self = shift;
        
        my $session = $app->sessions;
        my $id = $session->{'user_id'};
        # Anonymous has 1st id.
        $id ||= 1;
        
        $user->update( [$self->data->read( users => { id => $id } )]->[0] );
    });
    
    $app->helper (
        user => sub { $user }
    );
    
    # Routes
    my $route = $app->routes;
    my $r = $route->bridge('/user')->to('users#check_access');
    my $n = 'Mojolicious::Plugin::User::Controller';
    
    # User (CRUD+L)
    $route->route('/user/new')->via('get')->to( cb => sub {
        shift->render( template => 'users/form' )
    })->name('users_form');
    $route->route('/user/:id' , id => qr/\d+/)->via('get')->to('users#read', namespace => $n)->name('users_read');
    $route->route('/users/:id', id => qr/\d*/)->via('get')->to('users#list', namespace => $n)->name('users_list');
    $route->route('/user/new')->via('post')->to('users#create', namespace => $n)->name('users_create');
    $r->route('/:id', id => qr/\d+/)->via('put')->to('users#update', namespace => $n)->name('users_update');
    $r->route('/:id', id => qr/\d+/)->via('delete')->to('users#delete', namespace => $n)->name('users_delete');
    
    # Auth (Action)
    $r->route('/login')->via('post')->to('auths#login', namespace => $n)->name('auths_login');
    $r->route('/logout')->to('auths#logout', namespace => $n)->name('auths_logout');
    $route->route('/user/login')->via('get')->to( cb => sub {
        shift->render( template => 'auths/login_form' )
    } )->name('auths_login_form');
    # Login by mail:
    $route->route('/user/login/mail')->via('get')->to( cb => sub {
        shift->render( template => 'auths/login_mail_form' )
    } )->name('auths_login_mail_form');
    $route->route('/user/login/mail')->via('post')->to('auths#login_mail_request', namespace => $n)->name('auths_login_mail_request');
    $route->route('/user/login/mail/confirm')->to('auths#login_mail', namespace => $n)->name('auths_login_mail');
}

1;

__END__

=head2 Data Base Struct

=head3 User table

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

=head4 For MySQL

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

=head2 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

