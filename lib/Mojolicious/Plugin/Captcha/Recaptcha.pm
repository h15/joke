package Mojolicious::Plugin::Captcha::Recaptcha;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Storable 'freeze';

our $VERSION = '0.2';

sub register {
	my ($self,$app,$captcha) = @_;
	my $conf;
	
	# For Joke
	unless ( defined $captcha->config->{config}->{public_key} &&
	         defined $captcha->config->{config}->{private_key} ) {
	    
	    $app->data->update( jokes =>
	        {
	            config => freeze({
	                sub_plugin => 'Recaptcha',
	                config => {
	                    public_key  => '',
	                    private_key => ''
	                }
	            })
            },
	        { name => 'Captcha' }
	    );
	}
	else {
	    $conf = $captcha->config->{config};
	}
	# end
	
	$app->renderer->add_helper(
		captcha_html => sub {
			my $self = shift;
			my ($error) = map { $_ ? "&error=$_" : "" } $self->stash('recaptcha_error');
			return Mojo::ByteStream->new(<<HTML);
  <script type="text/javascript"
     src="http://www.google.com/recaptcha/api/challenge?k=$conf->{public_key}$error">
  </script>
  <noscript>
     <iframe src="http://www.google.com/recaptcha/api/noscript?k=$conf->{public_key}"
         height="300" width="500" frameborder="0"></iframe><br>
     <textarea name="recaptcha_challenge_field" rows="3" cols="40">
     </textarea>
     <input type="hidden" name="recaptcha_response_field"
         value="manual_challenge">
  </noscript>
HTML

		},
	);
	$app->renderer->add_helper(
		captcha => sub {
			my ($self,$challenge, $response) = @_;
			$response ||= 'manual_challenge';
			my $result;
			$self->client->post_form(
				'http://www.google.com/recaptcha/api/verify', 
				{
					privatekey => $conf->{'private_key'},
					remoteip   => 
						$self->req->headers->header('X-Real-IP')
						 ||
						$self->tx->{remote_address},
					challenge  => $self->req->param('recaptcha_challenge_field'),
					response   => $self->req->param('recaptcha_response_field')
				},
				sub {
					my $content = $_[1]->res->to_string;
					$result = $content =~ /true/;
					
					$self->stash(recaptcha_error => $content =~ m{false\s*(.*)$}si)
						unless $result
					;
				}
			)->start;
			
			$result;
		}
	);
}

1;

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2010 Dmitry Konstantinov. All right reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
