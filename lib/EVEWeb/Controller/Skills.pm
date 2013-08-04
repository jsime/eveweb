package EVEWeb::Controller::Skills;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Skills - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Skills', link => $c->uri_for('/skills') });

    my $res = $c->model('DB')->do(q{
        select *
        from ccp.skill_groups
        where published
        order by name asc
    });

    $c->stash->{'skill_groups'} = [];
    while ($res->next) {
        push(@{$c->stash->{'skill_groups'}}, { map { $_ => $res->{$_} } $res->columns });
    }
}


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{'template'} = 'skills/index.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
