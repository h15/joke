package Joke;
use Mojo::Base 'Mojolicious';
use Joke::Model;

has model_obj => undef;

# This method will run once at server start
sub startup {
    our $self = shift;
        $self->model_obj( new Joke::Model );
}

sub import {
    my ( $self, $base ) = @_;
    
    if ( $base ne '-base' ) {
        $base =~ s/::/\//g,
        require "$base.pm" unless $base->can('new')
    }
    else { $base = 'UNIVERSAL' }
    
    no strict 'refs';
    
    my $caller = caller;
       
    push @{"${caller}::ISA"}, $base, 'Mojo::Base';
         *{"${caller}::app"} = sub { $Joke::self };
}
#"

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

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

