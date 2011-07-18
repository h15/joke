package Joke::Base;
use Mojo::Base;

sub import {
    my ( $self, $base ) = @_;
    
    if ( $base ne '-base' ) {
        my $path = $base;
           $path =~ s/::/\//g,
           
        require "$path.pm" unless $base->can('new')
    }
    else { $base = 'UNIVERSAL' }
    
    no strict 'refs';
    
    my $caller = caller;
    
    push @{"${caller}::ISA"}, 'Mojo::Base', $base;
         *{"${caller}::has"} = sub { Mojo::Base::attr($caller, @_) };
         *{"${caller}::app"} = sub { $Joke::self };
}
#"

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

