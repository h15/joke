use strict;
use warnings;

package Mojolicious::Plugin::Data::Sql;

use DBIx::Simple;
use SQL::Abstract;

our $VERSION = '0.1';

# Params : db config.
# Returns: 0 if init failed || object.
sub new {
    my ( $self, $conf ) = @_;
    
    # init database handler.
    my $h = DBIx::Simple->connect (
        @$conf{ qw/host user passwd/ },
        {
            # some options.
            RaiseError => 1,
            mysql_enable_utf8 => 1
        }
    ) or return 0;
    
    $h->abstract = SQL::Abstract->new (
        case    => 'lower',
        logic   => 'and',
        convert => 'upper'
    );
    
    my $obj = {
        db      => $h,
        prefix  => $conf->{'prefix'}
    };
    
    bless $obj, $self;
}

#
#   CRUD again.
#

sub read {
    my $self = shift;
    my $table = shift;
    
    $self->{'db'}->select( $self->{'prefix'} . $table, @_ )->hashes;
}
    
sub update {
    my $self = shift;
    my $table = shift;
            
    $self->{'db'}->update( $self->{'prefix'} . $table, @_ );
}

sub create {
    my $self = shift;
    my $table = shift;
            
    $self->{'db'}->insert( $self->{'prefix'}.$table, @_, {returning => 'id'} );
}

    
sub delete {
    my $self = shift;
    my $table = shift;
            
    $self->{'db'}->delete( $self->{'prefix'} . $table, @_ );
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

