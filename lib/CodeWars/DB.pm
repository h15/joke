package CodeWars::DB;

use DBIx::Simple;
use SQL::Abstract;

my $dbHandler;

sub init {
    my ($self, $config) = @_;
    
    # init global database handler
    $dbHandler = DBIx::Simple->connect(
        @$config{ qw/host user passwd/ },
        {
            # some options
            RaiseError => 1,
            mysql_enable_utf8 => 1
        }
    ) or CodeWars::Utils->riseError("Cann't initialize database connection");

    $dbHandler->abstract = SQL::Abstract->new(
        case    => 'lower',
        logic   => 'and',
        convert => 'upper'
    );
}

sub handler {
	return $dbHandler;
}

1;
