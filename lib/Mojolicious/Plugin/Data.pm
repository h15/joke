package Mojolicious::Plugin::Data;
use Mojo::Base 'Mojolicious::Plugin';

has version => 0.1;
has about   => 'Data bases\' interface.';
has depends => sub { [ qw/Message/ ] };
has config  => sub { {
    sub_plugin => "Sql",
    config     => {
    # TODO: generate config in sub_plugin
        host    => 'dbi:mysql:joker',
        user    => 'joker',
        passwd  => 'fSZs4hCZusneJcbB',
        prefix  => 'joke__',
    }
} };

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
    
    my $class = "Mojolicious::Plugin::Data::" . $conf->{sub_plugin};
    load $class;
    my $drv = $class->new($conf->{config});
    
    # If data base driver init failed.
    return 0 unless $drv;
    
    my $obj = {driver => $drv};
    
    bless $obj, $self;
}

#
#       CRUD methods.
#
# Params : (table, {fields}).
# Returns: id of new object.
sub create {
    return shift->{driver}->create(@_);
}

# Params : (table, fields?, {where}, order?).
# Returns: array of hashes.
sub read {
    die "[-] You should not ever use read.\n".
        "    Now you can use list for the same.\n";
}

sub list {
    return shift->{driver}->list(@_);
}

sub read_one {
    return shift->{driver}->read(@_);
}

# Params : (table, {fields}, {where}).
# Returns: true || false.
sub update {
    return shift->{driver}->update(@_);
}

# Params : (table, {where}).
# Returns: true || false.
sub delete {
    return shift->{driver}->delete(@_);
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

