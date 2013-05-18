package EVEWeb::Model::DB;

use 5.010;
use strict;
use warnings;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'DBIx::DataStore' );

sub mangle_arguments {
    my ($self, $args) = @_;
    die unless exists $args->{'datastore'};
    return $args->{'datastore'};
}
