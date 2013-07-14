package EVEWeb::Controller::Pilot;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Pilot - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select p.*
        from eve.pilots p
        where p.pilot_id in ( select pk.pilot_id
                              from eve.pilot_api_keys pk
                                  join eve.api_keys k on (k.api_key_id = pk.api_key_id)
                              where k.user_id = ?
                            )
        order by p.name asc
    }, $c->stash->{'user'}{'user_id'});

    $c->stash->{'pilots'} = [];
    while ($res->next) {
        push(@{$c->stash->{'pilots'}}, { map { $_ => $res->{$_} } $res->columns });
    }

    $c->stash->{'template'} = 'pilot/index.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
