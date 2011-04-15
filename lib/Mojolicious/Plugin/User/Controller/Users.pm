package Mojolicious::Plugin::User::Controller::Users;
use Mojo::Base 'Mojolicious::Controller';

sub read {
    my $self = shift;
    
	# Get accounts by id.
	my @users = $self->data->read( users => { id => $self->stash('id') } );
    
    $self->error("User with this id doesn't exist!") if $#users;
    
    if ( $self->user->data->{'id'} != 1                         # not Anonymous
        && ( $self->param('id') == $self->user->data->{'id'}    # and Self
             || $self->user->is_admin()                         #   or Admin.
        ) ) {
        $self->read_extended(@users);
    }

    $self->stash( user => $users[0] );

    $self->render;
}

sub read_extended {
    my $self = shift;
    my @users = @_;
    
    $self->render(
        action => 'read_extended',
    );
}

sub create {
    my $self = shift;
    
    my $key = Digest::MD5::md5_hex(rand);
    
    my @users = $self->data->read( users => {mail => $self->param('mail')} );
    
    return $self->redirect_to('users_form') unless $#users;
    
    #
    #   TODO: Send mail
    #
    
    $self->data->create( users => {
        mail    => $self->param('mail'),
        regdate => time,
        confirm_time => time + 86400 * $self->joker->jokes->{'User'}->{'config'}->{'confirm'},
        confirm_key  => $key
    });
    
    $self->done('Check your mail.');
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

