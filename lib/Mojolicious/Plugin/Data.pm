package Mojolicious::Plugin::Data;
use Mojo::Base 'Mojolicious::Plugin';

has version => 0.1;
has about   => 'Data bases\' interface.';
has depends => sub { [ qw/Message/ ] };
has config  => sub { {
    driver => "Sql",
    auth   => {
        host    => 'dbi:mysql:joker',
        user    => 'joker',
        passwd  => 'fSZs4hCZusneJcbB',
        prefix  => 'joke__',
    }
} };

has joke => sub { 1 };

sub register {
    my ( $self, $app ) = @_;
    
    my $data = Mojolicious::Plugin::Data::Data->new( $self->config );
    
    $app->error('Cann\'t init data base.') unless $data;
    
    $app->helper(
        # For querys like $self->data->read,
        # where read is a method of Data.
        data => sub { $data }
    );
}

1;

package Mojolicious::Plugin::Data::Data;

use Module::Load;

#
#   Interface for data bases.
#

sub new {
    my ( $self, $conf ) = @_;
    
    my $class = "Mojolicious::Plugin::Data::" . $conf->{'driver'};
    load $class;
    my $drv = $class->new( $conf->{'auth'} );
    
    # If data base driver init failed.
    return 0 unless $drv;
    
    my $obj = { driver => $drv };
    
    bless $obj, $self;
}

#
#       CRUD methods.
#
# Params : (table, {fields}).
# Returns: id of new object.
sub create {
    return shift->{'driver'}->create(@_);
}

# Params : (table, fields?, {where}, order?).
# Returns: array of hashes.
sub read {
    return shift->{'driver'}->read(@_);
}

# Params : (table, {fields}, {where}).
# Returns: true || false.
sub update {
    return shift->{'driver'}->update(@_);
}

# Params : (table, {where}).
# Returns: true || false.
sub delete {
    return shift->{'driver'}->delete(@_);
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

