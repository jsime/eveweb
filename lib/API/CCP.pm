package API::CCP;

use 5.010;
use strict;
use warnings;

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    return $self;
}

sub auth {
    my ($self, $key_id, $v_code) = @_;
}

1;

