package EVEWeb::Log;

use strict;
use warnings FATAL => 'all';

use Moose;
use MooseX::SetOnce;
use namespace::autoclean;

use DateTime;
use Sys::Hostname;

=head1 CLASS METHODS

=cut

=head1 METHODS

=cut

sub debug {
    my ($self, @args) = @_;

    return $self->logger('DEBUG', @args);
}

sub info {
    my ($self, @args) = @_;

    return $self->logger('INFO', @args);
}

sub warn {
    my ($self, @args) = @_;

    return $self->logger('WARN', @args);
}

sub error {
    my ($self, @args) = @_;

    return $self->logger('ERROR', @args);
}

=head1 INTERNAL METHODS

=cut

sub logger {
    my ($self, $level, $message, @vars) = @_;

    my $l_time = scalar(localtime());
    $message = sprintf($message, @vars) if defined @vars && @vars > 0;

    printf('%s - %s/%d [%s] %s', $l_time, hostname(), $$, $message) . "\n";
}

__PACKAGE__->meta->make_immutable;

1;
