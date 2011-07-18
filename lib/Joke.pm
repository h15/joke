package Joke;
use Mojo::Base 'Mojolicious';

use Joke::Model;
use Joke::Config;

has model_obj  => undef;
has config_obj => undef;

# This method will run once at server start
sub startup {
    our $self = shift;
        $self->config_obj( new Joke::Config );
        $self->model_obj ( new Joke::Model  );    
}

sub model {
    my ( $self, $name, $id ) = @_;
    
    return $self->model_obj unless $name;
    
    # Defined NAME
    $self->model_obj->model($name);
    $self->model_obj->add_model( $name => 1 )
        unless exists $self->model_obj->models->{$name};
    
    # Defined ID
    if ( defined $id ) {
        return $self->model_obj->find (
            $self->model($name)->raw->meta->primary_key || 'id' => $id );
    }
    
    return $self->model_obj;
}

sub config {
    my ( $self, $name, $data ) = @_;
    
    return $self->config_obj unless $name;

    $self->config_obj->config($name);
    $self->config_obj->_set($name => $data) if defined $data;
    $self->config_obj->_get($name);
}

1;

__END__ 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

