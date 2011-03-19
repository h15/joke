package Mojolicious::Plugin::Text;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ( $self, $app, $conf ) = @_;
    
    $conf ||= {};
    
    $app->helper (
        text => sub {
            return shift;
        }
    );
    
    $app->helper (
        parse => sub {
            my ($self, $text) = @_;
            
            # For $self->text->parse->simple constructions.
            return $self unless $text;
            
            # Merge exts and imgs.
            my %merge;
            ++$merge{$_} for @{$conf->{exts}}, @{$conf->{imgs}};
            
            @{$conf->{exts}} = keys %merge;
            
            # Prepare string.
            $text = "\n#!\n" . $text . "\n#!\n";
            
            #
            my ($result, $str, $new_mode);
            my $mode = $conf->{'default'};
            
            #
            #   Parsing.
            #
            
            while( $text =~ /\G(.*?)\n#!(.*?)\n/gcs ) {
                ($str, $new_mode) = ( $1, $2 );
                
                #
                #   Select parser.
                #
                
                if( $mode eq 'simple' ) {
                    $result .= simple( $str, $conf );
                }
                else {
                    $result .= simple( $str, $conf );
                }
                
                $mode = $new_mode;
                $mode ||= $conf->{'default'};
            }
            
            return $result;
        }
    );
    
    $app->helper (
        simple => sub {
            my ($self, $text) = @_;
        }
    );
    
    #
    #   For mimeTex
    #
    
    $app->helper (
        tex => sub {
            my $self = shift;
            my $f = $self->stash('formula');
            
            #
            #   Prepare text
            #
            
            $f = "Wrong Format" if $f !~ /^[.,a-zA-Z0-9+()*{}^=_\-\/\\]*$/;
            $f =~ s/\\/\\\\/g;
            $f =~ s/([()])/\\$1/g;
            $f =~ s/\s+//g;
            
            my $file = Digest::MD5::md5_hex( $f ) . '.gif';
            
            system("mimetex -e ./public/img/tex/$file $f")
                unless -r './public/img/tex' . $file;
            
            $self->redirect_to('/img/tex/' . $file);
        }
    );
}

#
#   Link => <a rel class href="Link">.
#   Link to img => <a rel class href="Link"><img src="Link" /></a>.
#
sub simple {
    my ($str, $conf) = @_;
    
    my ($hosts, $protos, $exts, $imgs) = @$conf{ qw/hosts protos exts imgs/ };
    
    $str .= "\n";
    
    #
    #   Define small regexps.
    #
    
    my $proto_str = join '|', @$protos;
    my $ext_str   = join '|', @$exts;
    
    my $protocol = qr!(?:$proto_str)://!;
    my $userpass = qr!\S+?:\S+?@!;
    my $hostname = qr![^\s/\\]+?!;
    my $port = qr!:\d+!;
    
    # /smth many times.
    my $path = qr!(?:/[^\s/\\]+?)+?!;
    
    # /smth.smth || /smth || /.smth.
    my $file = qr!/(?:[^\s/\\]+?)?(?:\.($ext_str))?!;
    my $end  = qr/[()\[\]*!^\$@`"':;{}|,><\s]/;
    
    #
    #   Big regexp.
    #
    
    $str =~ s {
        ($protocol(?:$userpass)?($hostname)(?:$port)?(?:$path)?(?:$file)?)($end)
    }{
        '<a '
        . (
            # if $hostname in @$hosts.
            ( grep { $_ eq $2 } @$hosts ) ?
                'class="internal" ' :
                'rel="nofollow" class="external" '
        )
        . 'href="' . $1 . '">'
        . (
            # if $file's $ext in @$img_exts.
            ( grep { $_ eq $3 } @$imgs ) ?
                # it's image!
                "<img src=\"$1\" />" :
                # just url.
                $2
        )
        . '</a>' . $4;
    }exig;
    
    return $str;
}

1;
