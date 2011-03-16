package CodeWars::Drawer;

my %drawer;

sub put {
    my ($self, $data, $val) = shift;
    
    # $key => $val
    if ( $val ) {
        $drawer{$data} = $val;
    }
    
    # {
    #     $key1 => $val1,
    #       ...
    #     $keyN => $valN
    # }
    else {
        # Sorry for my perlish...
        $drawer{$_} = $data{$_} for keys %data;
    }
}

sub get {
    my ($self, $key) = shift;
	return $drawer{$key};
}

1;

