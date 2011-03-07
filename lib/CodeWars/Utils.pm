package CodeWars::Utils;

sub isMail {
	my ($shift, $mail) = @_;
	
	return true if $mail =~ m/^[a-z0-9_\-.]+@[a-z0-9_\-.]+$/i;
	return false;
}

sub riseError {
	my ($self, $message) = @_;
	
	$self->stash(
		message => $message
	);
	
	$self->render(
		template => 'error',
		format => 'html'
	);
		
	# Should never be here but who knows?..
	exit(0);
}

sub salt {                                                     # [SALT]
	return 'some long hash';
}

1;
