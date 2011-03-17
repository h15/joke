package Mojolicious::Plugin::Mail;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use Encode ();
use MIME::Lite;
use MIME::EncWords ();

use constant TEST     => $ENV{MOJO_MAIL_TEST} || 0;
use constant FROM     => 'test-mail-plugin@mojolicio.us';
use constant CHARSET  => 'UTF-8';
use constant ENCODING => 'base64';

our $VERSION = '0.8';

__PACKAGE__->attr(conf => sub { +{} });

sub register {
	my ($plugin, $app, $conf) = @_;
	
	# default values
	$conf->{from    } ||= FROM;
	$conf->{charset } ||= CHARSET;
	$conf->{encoding} ||= ENCODING;
	
	$plugin->conf( $conf ) if $conf;
	
	$app->renderer->add_helper(
		send_mail => sub {
			my $self = shift;
			my $args = @_ ? { @_ } : return;
			
			# simple interface
			unless (exists $args->{mail}) {
				$args->{mail}->{ $_->[1] } = delete $args->{ $_->[0] }
					for grep { $args->{ $_->[0] } }
						[to => 'To'], [from => 'From'], [cc => 'Cc'], [bcc => 'Bcc'], [subject => 'Subject'], [data => 'Data']
				;
			}
			
			# hidden data and subject
			
			my @stash =
				map  { $_ => $args->{$_} }
				grep { !/^(to|from|cc|bcc|subject|data|test|mail|attach|headers|attr|charset|mimeword|nomailer)$/ }
				keys %$args
			;
			
			$args->{mail}->{Data   } ||= $self->render_mail(@stash);
			$args->{mail}->{Subject} ||= $self->stash ('subject');
			
			my $msg  = $plugin->build( %$args );
			my $test = $args->{test} || TEST;
			$msg->send( $conf->{'how'}, @{$conf->{'howargs'}||[]} ) unless $test;
			
			return $msg->as_string;
		},
	);
	
	$app->renderer->add_helper(
		render_mail => sub {
			my $self = shift;
			my $data = $self->render_partial(@_, format => 'mail');
			
			delete @{$self->stash}{ qw(partial mojo.content mojo.rendered format) };
			return $data;
		},
	);
}

sub build {
	my $self = shift;
	my $conf = $self->conf;
	my $p    = { @_ };
	
	my $mail     = $p->{mail};
	my $charset  = $p->{charset } || $conf->{charset };
	my $encoding = $p->{encoding} || $conf->{encoding};
	my $encode   = $encoding eq 'base64' ? 'B' : 'Q';
	my $mimeword = defined $p->{mimeword} ? $p->{mimeword} : !$encoding ? 0 : 1;
	
	# tuning
	
	$mail->{From} ||= $conf->{from};
	$mail->{Type} ||= $conf->{type};
	
	if ($mail->{Data}) {
		$mail->{Encoding} ||= $encoding;
		_enc($mail->{Data});
	}
	
	if ($mimeword) {
		$_ = MIME::EncWords::encode_mimeword($_, $encode, $charset) for grep { _enc($_); 1 } $mail->{Subject};
		
		for (grep { $mail->{$_} } qw(From To Cc Bcc)) {
			$mail->{$_} = join ",\n",
				grep {
					_enc($_);
					{
						next unless /(.*) \s+ (\S+ @ .*)/x;
						
						my($name, $email) = ($1, $2);
						$email =~ s/(^<+|>+$)//sg;
						
						$_ = $name =~ /^[\w\s"'.,]+$/
							? "$name <$email>"
							: MIME::EncWords::encode_mimeword($name, $encode, $charset) . " <$email>"
						;
					}
					1;
				}
				split /\s*,\s*/, $mail->{$_}
			;
		}
	}
	
	# year, baby!
	
	my $msg = MIME::Lite->new( %$mail );
	
	# header
	$msg->delete('X-Mailer'); # remove default MIME::Lite header
	$msg->add   ( %$_ ) for @{$p->{headers} || []}; # XXX: add From|To|Cc|Bcc => ... (mimeword)
	$msg->add   ('X-Mailer' => join ' ', 'Mojolicious',  $Mojolicious::VERSION, __PACKAGE__, $VERSION, '(Perl)')
		unless $msg->get('X-Mailer') || $p->{nomailer};
	
	# attr
	$msg->attr( %$_ ) for @{$p->{attr   } || []};
	$msg->attr('content-type.charset' => $charset) if $charset;
	
	# attach
	$msg->attach( %$_ ) for
		grep {
			if (!$_->{Type} || $_->{Type} eq 'TEXT') {
				$_->{Encoding} ||= $encoding;
				_enc($_->{Data});
			}
			1;
		}
		grep { $_->{Data} || $_->{Path} }
		@{$p->{attach} || []}
	;
	
	return $msg;
}

sub _enc($) {
	Encode::_utf8_off($_[0]) if $_[0] && Encode::is_utf8($_[0]);
	return $_[0];
}

1;

__END__

=head1 AUTHOR

Anatoly Sharifulin <sharifulin@gmail.com>

=head1 THANKS

Alex Kapranoff <kapranoff@gmail.com>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

