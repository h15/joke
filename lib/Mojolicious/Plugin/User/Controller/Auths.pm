package Mojolicious::Plugin::User::Controller::Auths;

use base 'Mojolicious::Controller';

sub login {
	my $self = shift;
	
	# It's not an e-mail!
	$self->IS( mail => $self->param('mail')	);
	
	# Get accounts by e-mail.
	my @users = $self->data->read( users => '*', {email => $self->param('mail')} );
    
    # If this e-mail does not exist
    # or more than one account has this e-mail.
    $self->error("This pair(e-mail and password) doesn't exist!") if $#users;
    
    my $user = $users[0];
    
    # Password test:
    #   hash != md5( regdate + password + salt )
    my $s = $user->{'regdate'} . $self->param('passwd') . $self->stash('salt');
    
    if ( $user->{'password'} ne Digest::MD5::md5_hex($s) ) {
        return $self->error( "This pair(e-mail and password) doesn't exist!" );
    }
    
    # Init session.
    $self->session (
        user_id  => $user->{'id'},
    )->redirect_to( 'users_read', id => $user->{'id'} );
}

sub logout {
    shift->session( user_id => '' )->redirect_to('index');
}

sub login_mail_request {
    my $self = shift;
    
	$self->IS( mail => $self->param('mail') );
	
    # Get accounts by e-mail.
	my @users = $self->select( users => '*' => {email => $self->param('mail')} );
    
    # if 0 - all fine
    $self->error( "This e-mail doesn't exist in data base!" ) if $#users;
    
    # Generate and save confirm key.
    my $confirm_key = Digest::MD5::md5_hex(rand);
    
    $self->update(
        users =>
        {
            confirm_key  => $confirm_key,
            confirm_date => time
        },
        { email => $self->param('mail') }
    );
    
    # Send mail
    $self->mail->confirm ({
        reason  => 'Change password',
        mail    => $self->param('mail'),
        key     => $confirm_key
    }); 
}

sub login_mail {
    my $self = shift;
    my $mail = $self->param('mail');
    
    my @users = $self->data->read( users => {
        mail => $mail,
        confirm_key => $self->param('key')
    });
    # This pair does not exist.
    return $self->error('Auth failed!') unless $#users;
    
    # Too late
    if ( $users[0]->{'confirm_time'} > time + 86400 * $self->user->config->{'confirm'} ) {
        $self->data->update( user =>
            { confirm_key => '', confirm_time => 0 },
            { mail => $mail }
        );
        return $self->error('Auth failed (too late)!');
    }
    
    my $user = [ $self->data->read( users => {mail => $mail} ) ]->[0];
    
    $self->session (
        user_id  => $user->{'id'},
    )->redirect_to( 'users_read', id => $user->{'id'} );
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

