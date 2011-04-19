package Mojolicious::Plugin::User;
use Mojo::Base 'Mojolicious::Plugin';

use Digest::MD5 "md5_hex";
use MIME::Base64;

use Mojolicious::Plugin::User::User;

has version => 0.2;
has about   => 'Plugin for Users system.';
has depends => sub { [ qw/Data Message Mail/ ] };
has config  => sub {{
    cookies => 'some random string',
    confirm => 7,
    salt    => '',
}};

sub joke {
    my $self = shift;    
    {
       version => $self->version,
       about   => $self->about,
       depends => $self->depends,
       config  => $self->config
    }
}

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
    my ( $c, $app ) = @_;
    my $self = new Mojolicious::Plugin::User;
    my $user = new Mojolicious::Plugin::User::User;
    
    $app->secret( $self->config->{'cookies'} );
    $app->sessions->default_expiration(3600*24*7);
    
    # Run on any request!
    $app->hook( before_dispatch => sub {
        my $self = shift;
        
        my $id = $self->session('user_id');
        # Anonymous has 1st id.
        $id ||= 1;
        
        $app->stash( banned => 0 );
        $user->update( [$self->data->read( users => { id => $id } )]->[0] );
        
        unless ( $user->is_active ) {
            my $ban = $user->data->{'ban_reason'};
            $user->update( [$self->data->read( users => { id => 1 } )]->[0] );
            $user->data->{'ban_reason'} = $ban;
        }
    });
    
    $app->helper( user => sub { $user } );
    
    $app->stash( salt => $app->joker->jokes->{'User'}->{'config'}->{'salt'} );
    
    # Routes
    my $r = $app->routes->route('/user')->to( namespace => 'Mojolicious::Plugin::User::Controller' );
    
    # User CRU(+L)D
    $r->route('/new')->via('post')->to('users#create')->name('users_create');
    $r->route('/new')->via('get')->to( cb => sub { shift->render( template => 'users/form' ) })->name('users_form');
    $r->route('/:id', id => qr/\d+/)->via('get')->to('users#read')->name('users_read');
    $r->route('/list/:id', id => qr/\d*/)->to('users#list')->name('users_list');
    $r->route('/:id', id => qr/\d+/)->via('post')->to('users#update')->name('users_update');
    $r->route('/:id', id => qr/\d+/)->via('delete')->to('users#delete')->name('users_delete');
    
    # Login by mail:
    $r->route('/login/mail/confirm')->to('auths#mail_confirm')->name('auths_mail_confirm');
    $r->route('/login/mail')->via('post')->to('auths#mail_request')->name('auths_mail_request');
    $r->route('/login/mail')->via('get')->to( cb => sub { shift->render( template => 'auths/mail_form' ) } )->name('auths_mail_form');
    # Auth Create and Delete regulary and via mail
    $r->route('/login')->via('post')->to('auths#login')->name('auths_login');
    $r->route('/login')->via('get')->to( cb => sub { shift->render( template => 'auths/form' ) } )->name('auths_form');
    $r->route('/logout')->to('auths#logout')->name('auths_logout');
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

