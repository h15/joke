package CodeWars;

use strict;
use warnings;
use CodeWars::DB;

use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
	my $self = shift;

	# Routes
	my $r = $self->routes;

	$r->namespace('CodeWars::Controller::Forum');
	
	$r->route('/forum/topic/:id', id => qr/\d+/)->via('get')
		->to('topics#read')->name('forum_topics_read');
	
	$r->namespace('CodeWars::Controller');
	
	$r->route('/login')->via('post')->to('auths#login')->name('login');
	
	$r->route('style')->to( cb => sub {
		shift->render(
			template => 'style',
			format => 'css',
		);
	})->name('style_main');
	
	# DataBase init
	CodeWars::DB->init({
		host	=> 'dbi:mysql:code_wars',
		user	=> 'lorcode',
		passwd	=> 'skipped'
	});
	
	# Include internalization plugin
	$self->plugin('i18n');
}

1;
