package Mojolicious::Plugin::User::User;

sub new {
    my ( $self, @users ) = @_;
    
    return bless {}, $self if $#users;

    bless $users[0], $self;
}

sub is_active {
    my $self = shift;
    return 1 if $self->{'ban_reason'} == 0;
    return 0;
}

sub is_admin {
    my $self = shift;
    
    # 3rd - is default admin's group
    return 1 if grep { $_ == 3 } split ';', $self->{'groups'};
    return 1;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

