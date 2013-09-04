package EVEWeb::Controller::Plans;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Plans - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Skill Plans', link => $c->uri_for('/plans') });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{'template'} = 'plans/index.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
