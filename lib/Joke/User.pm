package Joke::User;
use Joke::Base -base;
use URI::Escape 'uri_escape';
use Digest::MD5 'md5_hex';

has data => undef;

sub init {
    my $self = shift;
    
    my $conf = $self->app->config('User');
    
    $self->app->secret( $conf->{secret} );
    $self->app->sessions->default_expiration( 3600 * 24 * $conf->{confirm} );
    
    # Run on any request!
    $self->app->hook( before_dispatch => sub {
        my $c = shift;
        
        my $id = $c->session('user_id');
        # Anonymous has 1st id.
        $id ||= 1;
        
        $self->data = $self->app->model( 'User', $id );
        
        unless ( $self->data->is_active ) {
            my $ban = $self->data->ban_reason;
            $self->data = $self->app->model( 'User', 1 );
            $self->data->ban_reason($ban);
        }
    });
    
    # Routes
    my $r = $self->app->routes->route('/user')->to( namespace => 'Joke::User::Controller' );
    
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
    $r->route('/login' )->via('post')->to('auths#login')->name('auths_login');
    $r->route('/login' )->via('get')->to( cb => sub { shift->render( template => 'auths/form' ) } )->name('auths_form');
    $r->route('/logout')->to('auths#logout')->name('auths_logout');
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

