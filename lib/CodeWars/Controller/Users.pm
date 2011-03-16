package CodeWars::Controller::Users;

use Digest::MD5 'md5_hex';

use base 'Mojolicious::Controller';

sub read {
    my $self = shift;
    
	# Get accounts by id.
	my @users = $self->select( users => '*', { id => $self->stash('id') } );
    
    $self->error("User with this id doesn't exist!") if $#users;
    
    if( $self->user->{'id'} != 1                        # not Anonymous
        && $self->stash('id') == $self->user->{'id'}    # and Self
        || $self->user->isAdmin() ) {                   # or  Admin.
        
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

sub forgotForm {
    #
    #   TODO: counter & CAPTCHA
    #
    my $self = shift;
    
    $self->render;
}

sub forgotRequest {
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
            confirm_time => time
        },
        
        # where
        {
            email => $self->param('mail')
        }
    );
    
    #
    # Send mail
    #
    
    $self->mail( confirm => {
        mail => $self->param('mail'),
        key  => $confirm_key
    }); 
}

1;
