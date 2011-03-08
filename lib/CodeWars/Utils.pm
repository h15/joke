package CodeWars::Utils;

use base 'Mojolicious::Controller';

my ($canTrollErr, $salt);

sub init {
    my $self = shift;
    ($canTrollErr, $salt) = @_;
}

sub isMail {
	my ($elf, $mail) = @_;
	
	return true if $mail =~ m/^[a-z0-9_\-.]+@[a-z0-9_\-.]+$/i;
	return false;
}

sub riseError {
	my ($self, $message) = @_;
	
	$canTrollErr->stash(
		message => $message
	);
	
	$canTrollErr->render(
		template => 'error',
		format => 'html'
	);
		
	# Should never be here but who knows?..
	exit(0);
}

sub salt {                                                     # [SALT]
	return $salt;
}

1;
