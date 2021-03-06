package Joke::Model;
use Joke::Base -base;

use Storable 'freeze';

has models => sub {{}};
has model  => undef;

sub init {
    my $self = shift;

    my $path = "./lib/Joke/Model/Config.pm";
    my $code = freeze( $self->app->config('db') );
    
    open  FILE, "> $path" or die "[-] Cann't write into file $path";
   
    print FILE qq { # Autogenerated by MojoM.
                    # Be careful when edit it.
                    
                    package Joke::Model::Config;
                    use base 'Rose::DB';
                    
                    __PACKAGE__->use_private_registry;
                    __PACKAGE__->default_connect_options( mysql_enable_utf8 => 1 );
                    
                    use Storable 'thaw';
                    
                    my \$a = thaw('$code');
                    
                    __PACKAGE__->register_db ( \%\$a );
                    
                    1;
                  };
    
    close FILE;
}

sub add_model {
    my ( $self, $key, $val ) = @_;
    
    $self->models ({
        %{$self->models},
        $key => $val
    });
}

sub init {
    my ( $self, @fields ) = @_;
    
    return $self unless @fields;
    
    my $code  = freeze( \@fields );
    my $name  = $self->model;
    my $class = "Joke::Model::$name";
    my $path  = "./lib/$class.pm";
       $path  =~ s/::/\//g;
       
    open  FILE, "> $path" or die "[-] Cann't write into file $path";

    print FILE qq { # Autogenerated by MojoM.
                    # Be careful when edit it.
                    
                    package Joke::Model::$name;
                    use base 'Joke::Model::Base';
                    
                    use Storable 'thaw';

                    my \$a = thaw('$code');

                    __PACKAGE__->meta->setup( \@\$a );
                    
                    # Manager
                    
                    package Joke::Model::${name}::Manager;
                    use base 'Rose::DB::Object::Manager';

                    sub object_class { 'Joke::Model::$name' }

                    __PACKAGE__->make_manager_methods( lc '$name' );

                    1;
                  };

    close FILE;
    
    return $self;
}
    
sub find {
    my ( $self, @fields ) = @_;
    
    my $name  = $self->model;
    my $class = "Joke::Model::$name";
    
    eval "require $class";
    
    if ( $class->new(@fields)->load(speculative => 1) ) {
        return $class->new(@fields)->load;
    }
    
    Mojolicious->log->error (
        "Trying to get a nonexistent record from the database!\n".
        $self->app->dumper(\@fields)
    );
    
    return 0;
}
    
sub create {
    my ( $self, @fields ) = @_;
    
    my $name  = $self->model;
    my $class = "Joke::Model::$name";
    
    eval "require $class";
    
    return $class->new(@fields);
}
    
sub exists {
    my ( $self, @fields ) = @_;
    
    my $name  = $self->model;
    my $class = "Joke::Model::$name";
    
    eval "require $class";
    
    $class->new(@fields)->load(speculative => 1) ? 1 : 0;
}

sub list {
    my ( $self, @fields ) = @_;
    
    my $name  = $self->model;
    my $class = "Joke::Model::${name}::Manager";
    
    eval "require $class";
    
    $class->get_objects(
        @fields,
        object_class => "Joke::Model::$name"
    )
}

sub range {
    my ( $self, $start, $offset ) = @_;
    
    $self->list(
        sort_by => 'id DESC',
        limit   => $offset,
        offset  => $start,
    );
}

sub raw {
    my $self  = shift;
    my $name  = $self->model;
    my $class = "Joke::Model::$name";
    
    eval "require $class";
    
    return $class;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

