package CodeWars;

use CodeWars::Drawer;

use Mojo::Base 'Mojolicious';

my $config = {
    cookies => 'some random string',
    salt    => 'some random string',
    db      => {
        host    => 'dbi:mysql:code_wars',
        user    => 'code_wars',
        passwd  => 'SCKM4FJS57BRL49x',
        prefix  => 'forum__',
    },
};

# This method will run once at server start
sub startup {
    my $self = shift;
    
    # Mode, signed cookies' secret, session time
    $self->mode('development');
    $self->secret( $config->{'cookies'} );
    $self->sessions->default_expiration(3600*24*7);

    $self->stash( salt => $config->{'salt'} );
    
    #
    #   Routes
    #
    my $r = $self->routes;
    $r->namespace('CodeWars::Controller');
    
    #$r->route('/')->to('news#list', size => 10)->name('index');
    
    # News
    #$r->route('/news/:id', id => qr/\d+/)->via('get')
    #    ->to('news#read')->name('news_read');
    #$r->route('/news/new', id => qr/\d+/)->via('post')
    #    ->to('news#create')->name('news_create');
    
    # Sessions
    $r->route('/login')->via('get' )->to('auths#form' )->name('auths_form' );
    $r->route('/login')->via('post')->to('auths#login')->name('auths_login');
    $r->route('/logout')->to('auths#logout')->name('auths_logout');
    
    # User
    $r->route('/user/:id', id => qr/\d+/)->via('get')->to('users#read')
        ->name('users_read');
    #$r->route('/user/:id', id => qr/\d+/)->via('put')->to('users#update');
    #$r->route('/user/:id', id => qr/\d+/)->via('delete')->to('users#delete');
    #$r->route('/user/new')->via('post')->to('users#create')
    #    ->name('users_create');
    
    # Restore passwords
    $r->route('/user/forgot')->via('get')->to('users#forgotForm')
        ->name('users_forgot_form');
    $r->route('/user/forgot')->via('post')->to('users#forgotRequest')
        ->name('users_forgot_request');
    
    # Thread
    $r->route('/thread/:id', id => qr/\d+/)->via('get')->to('threads#read')
        ->name('threads_read');
    
    #
    #   Plugins
    #
    $self->plugin( mail => {
        from     => 'no-reply@lorcode.org',
        encoding => 'base64',
        type     => 'text/html',
        how      => 'sendmail',
        howargs  => [ '/usr/sbin/sendmail -t' ],
    });
    
    $self->plugin( sql => $config->{'db'} );
    
    my $session = $self->sessions;
    $self->plugin( user => $session->{'user_id'} );
    
    # Load plugins without configure.
    my @plugins = qw[email i18n message validate];
    $self->plugin($_) for @plugins;
}

1;
