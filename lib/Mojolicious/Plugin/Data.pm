use strict;
use warnings;

package Mojolicious::Plugin::Data;

use base 'Mojolicious::Plugin';

our $VERSION = '0.1';

#
#   Info method for Joker plugin manager.
#

sub info {
    my ($self, $field) = @_;
    
    my $info = {
        version => $VERSION,
        author  => 'h15 <georgy.bazhukov@gmail.com>',
        about   => 'Data bases\' interface.',
        fields  => {},
        depends => [ qw/Message/ ],
        config  => {
        #
        # Default config. Will be deleted.
        #
        # Should set this config in some other place...
        #
            driver => "Sql",
            auth   => {
                host    => 'dbi:mysql:code_wars',
                user    => 'code_wars',
                passwd  => 'SCKM4FJS57BRL49x',
                prefix  => 'forum__',
            }
        }
    };
    
    return $info->{$field} if $field;
    return $info;
}

sub register {
    my ( $self, $app ) = @_;
    
    #$app->plugin('message');
    
    my $data = Mojolicious::Plugin::Data::Data->new( $self->info('config') );
    
    $app->error('Cann\'t init data base.') unless $data;
    
    $app->helper(
        # For querys like $self->data->read,
        # where read is a method of Data.
        data => sub {
            my $self = shift;
            return $data;
        }
    );
}

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

