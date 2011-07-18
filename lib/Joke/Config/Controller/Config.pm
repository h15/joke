package Joke::Config::Controller::Config;
use Joke::Base 'Mojolicious::Controller';

sub list {
    my $self = shift;
    
    my @keys = sort keys %{ $self->config_obj->configs };
    
    $self->stash (
        configs => \@keys,
        config  => $self->config( $keys[0] )
    );
    
    $self->render;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

