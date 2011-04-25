package Mojolicious::Plugin::Wiki;
use Mojo::Base 'Mojolicious::Plugin';

has version => 0.1;
has about   => 'Wiki-like system.';
has depends => sub { [ qw/Data Message User/ ] };
has config  => sub { {} };

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
    
    # Routes
    my $r = $app->routes->route('/wiki')->to( namespace => 'Mojolicious::Plugin::Wiki::Controller' );
    
    # User CRU
    $r->route('/new')->via('post')->to('wikis#create')->name('wikis_create');
    $r->route('/new')->via('get')->to( cb => sub { shift->render( template => 'wikis/form' ) })->name('wikis_form');
    $r->route('/:article', article => qr/\d*/)->via('post')->to('wikis#update')->name('wikis_update');
    $r->route('/:article/:revision', [qw/article revision/] => qr/\d*/)->via('get')->to('wikis#read')->name('wikis_read');
}

1;

package Mojolicious::Plugin::Wiki::Controller::Wikis;
use Mojo::Base 'Mojolicious::Controller';

sub create {
    my $self = shift;
    
    my $art_id = $self->data->create( wiki_article => {
        revision_id => 0,
        title => $self->param('title'),
        status => 0,
    });
    
    my $rev_id = $self->data->create( wiki_revision => {
        article_id => $art_id,
        user => $self->user->data->{id},
        text => $self->param('text'),
        datetime => time,
    });
    
    $self->data->update (
        wiki_article => 
        { revision_id => $rev_id },
        { id => $art_id }
    );
    
    $self->redirect_to( 'wikis_read', article => $art_id, revision => $rev_id );
}

sub read {
    my $self = shift;
    
    my $art_id = $self->param('article');
    $art_id ||= 0;
    
    my $art = $self->data->read_one( wiki_article => { id => $art_id } );

    my $rev_id = ( $self->param('revision') ? $self->param('revision') : $art->{revision} );

    my $rev = $self->data->read_one( wiki_revision => { id => $rev_id } );
    
    $self->stash (
        title => $art->{title},
        rev_text => $rev->{text},
        art_status => $art->{status},
        datetime => $rev->{datetime},
        rev_id => $rev_id,
        active_rev => $art->{revision_id},
        user => $rev->{user}
    );
    
    $self->render;
}

sub update {
    my $self = shift;
    
    return $self->error('You cannot change article status!') if $self->param('status') & 1 && ! $self->user->is_admin;
    return $self->error('You cannot change article title!') if $self->param('title') && ! $self->user->is_admin;
    
    my $art = $self->data->read_one( wiki_article => { id => $self->param('article') } );
    return $self->error('Article protected!') if $art->{status} & 1 && ! $self->user->is_admin;
    
    my $id = $self->data->create( wiki_revision => {
        article_id => $art->{id},
        user => $self->user->data->{id},
        text => $self->param('text'),
        datetime => time,
    });
    
    my %new = ( revision_id => $id );
    %new = ( %new, status => $self->param('status') ) if $self->param('status') && $self->user->is_admin;
    %new = ( %new, title => $self->param('title') ) if $self->param('title') && $self->user->is_admin;
    
    $self->data->update (
        wiki_article =>
        \%new,
        { id => $art->{id} }
    );
    
    $self->redirect_to( 'wikis_read', article => $art->{id} )
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

