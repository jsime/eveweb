package EVEWeb::Job;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

use DateTime;

has 'job_id' => (
    is  => 'ro',
    isa => 'Num',
);

has 'type' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'key' => (
    is  => 'ro',
    isa => 'Str',
);

has 'db' => (
    is       => 'ro',
    isa      => 'DBIx::DataStore',
    required => 1,
);

has 'stash' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'run_at' => (
    is      => 'rw',
    isa     => 'DateTime',
    default => sub { DateTime->now },
);

has 'started' => (
    is  => 'rw',
    isa => 'DateTime',
);

has 'finished' => (
    is  => 'rw',
    isa => 'DateTime',
);

has 'host' => (
    is  => 'ro',
    isa => 'Str',
);

has 'pid' => (
    is  => 'ro',
    isa => 'Int',
);

=head1 CLASS METHODS

=cut

sub claim {
    my ($class, $db, $type) = @_;
}

=head1 METHODS

=cut

sub start {
    my ($self) = @_;
}

sub finish {
    my ($self) = @_;
}

sub save {
    my ($self) = @_;
}

=head1 INTERNAL FUNCTIONS

=cut

__PACKAGE__->meta->make_immutable;

1;
