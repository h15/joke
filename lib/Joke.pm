package Joke;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    our $self = shift;
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

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

