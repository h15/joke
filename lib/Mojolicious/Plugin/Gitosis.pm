package Mojolicious::Plugin::Gitosis;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::Gitosis::EasyConfig;

has version => 0.1;
has about   => 'Gitosis interface';
has depends => sub { [ qw/Message User/ ] };
has config  => sub {{
    git_home => '/home/h15/my/gitosis-admin/'
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
    my ( $c, $app ) = @_;
    my $self = new Mojolicious::Plugin::Gitosis;
    my $conf = new Mojolicious::Plugin::Gitosis::EasyConfig({
        file => $self->config->{git_home} . 'gitosis.conf'
    });
    
    $app->helper( gitosis => sub{ $conf } );
    
    # Routes
    my $r = $app->routes->route('/git')->to( namespace => 'Mojolicious::Plugin::Gitosis::Controller' );
    
    $r->route('/')->via('get')->to('gits#list')->name('gits_index');
    $r->route('/new')->via('post')->to('gits#create_repo')->name('gits_create');
    $r->route('/new')->via('get')->to(cb => sub { shift->render(template => 'gits/form') })->name('gits_new');
    $r->route('/key')->via('post')->to('gits#add_key', dir => $self->config->{git_home} )->name('gits_key');
    $r->route('/key')->via('get')->to(cb => sub { shift->render(template => 'gits/key_form') })->name('gits_key_form');
    $r->route('/:repo')->via('post')->to('gits#update')->name('gits_update');
    $r->route('/:repo')->via('get')->to('gits#read')->name('gits_read');
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

