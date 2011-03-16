package Mojolicious::Plugin::Sql;

use strict;
use warnings;

use DBIx::Simple;
use SQL::Abstract;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.1';

sub register {
    my ( $self, $app, $config ) = @_;
    
    # init database handler
    my $h = DBIx::Simple->connect (
        @$config{ qw/host user passwd/ },
        {
            # some options
            RaiseError => 1,
            mysql_enable_utf8 => 1
        }
    ) or $self->error("Cannot initialize database connection");
    
    $h->abstract = SQL::Abstract->new (
        case    => 'lower',
        logic   => 'and',
        convert => 'upper'
    );
    
    #
    #   Helpers for CRUD
    #
    
    $app->helper (
        select => sub {
            my ($self, $table, $fields, $data) = @_;
            
            $h->select( $config->{'prefix'} . $table, $fields, $data )->hashes;
        }
    );
    
    $app->helper (
        update => sub {
            my ($self, $table, $fields, $data, $where) = @_;
            
            $h->update( $config->{'prefix'} . $table, $fields, $data, $where );
        }
    );
    
    $app->helper (
        insert => sub {
            my ($self, $table, $fields, $data) = @_;
            
            return $h->insert( $config->{'prefix'} . $table, $fields, $data,
                {
                    returning => 'id'
                }
            );
        }
    );
    
    $app->helper (
        delete => sub {
            my ($self, $table, $where) = @_;
            
            $h->delete( $config->{'prefix'} . $table, $where );
        }
    );
}

1;

