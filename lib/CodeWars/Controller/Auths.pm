package CodeWars::Controller::Auths;

use Digest::MD5 'md5_hex';

use base 'Mojolicious::Controller';

sub login {
    #
    #   TODO: Login attempts counter for ip via CodeWars::Utils
    #
    
	my $self = shift;
	
	# It's not an e-mail!
	$self->IS( mail => $self->param('mail')	);
	
	# Get accounts by e-mail.
	my @users = $self->select( users => '*', {email => $self->param('mail')} );
    
    # If this e-mail does not exist
    # or more than one account has this e-mail.
    $self->error("This pair(e-mail and password) doesn't exist!") if $#users;
    
    my $user = $users[0];
    
    # Password test:
    #   hash != md5( regdate + password + salt )
    my $s = $user->{'regdate'} . $self->param('passwd') . $self->stash('salt');
    
    if ( $user->{'password'} ne md5_hex($s) ) {
        $self->error( "This pair(e-mail and password) doesn't exist!" );
        
        # Don't work without return. I don't know why.
        return;
    }
    
    # Init session.
    $self->session(
        user_id  => $user->{'id'},
    )->redirect_to('index');
}

sub logout {
    my $self = shift;
    
    # Delete session.
	$self->session(
		user_id  => '',
	)->redirect_to('index');
}

sub form {
    my $self = shift;
    
    #
    #   TODO: Login counter and CAPTCHA
    #
    
    $self->render;
}


sub login_by_mail_form {
    #
    #   TODO: counter & CAPTCHA
    #
    my $self = shift;
    
    $self->render;
}

sub login_by_mail_request {
    my $self = shift;
    
    #
    #   Check input
    #
	
	$self->IS( mail => $self->param('mail') );
	
    # Get accounts by e-mail.
	my @users = $self->select( users => '*' => {email => $self->param('mail')} );
    
    # if 0 - all fine
    $self->error( "This e-mail doesn't exist in data base!" ) if $#users;
    
    #
    # Generate and save confirm key.
    #
    
    my $confirm_key = md5_hex(rand);
    
    $self->update(
        "users",
        
        # fields
        {
            confirm_key  => $confirm_key,
            confirm_date => time
        },
        
        # where
        {
            email => $self->param('mail')
        }
    );
    
    #
    # Send mail
    #
    
    $self->mail->confirm ({
        reason  => 'Change password',
        mail    => $self->param('mail'),
        key     => $confirm_key
    }); 
}

1;

