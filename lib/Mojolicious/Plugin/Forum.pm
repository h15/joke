package Mojolicious::Plugin::Forum;
use Mojo::Base 'Mojolicious::Plugin';

has version => 0.1;
has about   => 'Forum';
has depends => sub { [ qw/Message User Data/ ] };
has config  => sub {{
    posts_per_page => 10
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

sub register {
    my ( $self, $app ) = @_;
    
    # Routes
    my $r = $app->routes->route('/thread')->to( namespace => 'Mojolicious::Plugin::Forum::Controller' );
    
    # Threads
    $r->route('/new')->via('get')->to(
        cb => sub { shift->render( template => 'threads/form' ) }
    )->name('threads_form');
    $r->route('/new')->via('post')->to('threads#create')->name('threads_create');
    $r->route('/:id', id => qr/\d+/)->via('get')->to('threads#read')->name('threads_read');
    $r->route('/:id', id => qr/\d+/)->via('post')->to('threads#update')->name('threads_update');
    
    # Posts
    $r->route('/:thread/new', thread => qr/\d+/)->via('post')->to('posts#create')->name('posts_create');
    $r->route('/:thread/:post', [qw/thread post/] => qr/\d+/)->via('get')->to('posts#read')->name('posts_read');
#    $r->route('/:thread/:post', [qw/thread post/] => qr/\d+/)->via('post')->to('posts#update')->name('posts_update');
}

1;

__END__

=head2 SQL data base

    CREATE TABLE `joker`.`joke__posts` (
        `id` INT( 11 ) UNSIGNED NOT NULL AUTO_INCREMENT ,
        `thread_id` INT( 11 ) UNSIGNED NOT NULL ,
        `parent_id` INT( 11 ) UNSIGNED NOT NULL ,
        `post_time` INT( 11 ) UNSIGNED NOT NULL ,
        `author` INT( 11 ) UNSIGNED NOT NULL ,
        `text` TEXT CHARACTER SET utf8 COLLATE utf8_bin NOT NULL ,
        PRIMARY KEY ( `id` ) ,
        INDEX ( `id` )
    ) ENGINE = MYISAM ;
    
    CREATE TABLE `joker`.`joke__threads` (
        `id` INT( 11 ) UNSIGNED NOT NULL ,
        `parent_id` INT( 11 ) UNSIGNED NOT NULL ,
        `post_id` INT( 11 ) UNSIGNED NOT NULL,
        PRIMARY KEY ( `id` ) ,
        INDEX ( `id` )
    ) ENGINE = MYISAM ;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

