package EVEWeb::Controller::Pilots;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Pilots - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Pilots', link => $c->uri_for('/pilots') });
}


=head2 index

=cut

sub index :Path Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select p.*, c.corporation_id, c.name as corporation_name
        from eve.pilots p
            left join eve.pilot_corporations pc on (pc.pilot_id = p.pilot_id)
            left join eve.corporations c on (c.corporation_id = pc.corporation_id)
        where p.pilot_id in ( select pk.pilot_id
                              from eve.pilot_api_keys pk
                                  join eve.api_keys k on (k.key_id = pk.key_id)
                              where k.user_id = ?
                            )
            and pc.to_datetime is null
        order by p.name asc
    }, $c->stash->{'user'}{'user_id'});

    $c->stash->{'pilots'} = [];
    while ($res->next) {
        push(@{$c->stash->{'pilots'}}, { map { $_ => $res->{$_} } $res->columns });
    }

    $c->stash->{'template'} = 'pilots/index.tt2';
}

sub pilots : PathPath Chained('/') Args(1) {
    my ($self, $c, $pilot_id) = @_;

    my $res = $c->model('DB')->do(q{
        select p.*
        from eve.pilots p
        where p.pilot_id = ?
    }, $pilot_id);

    unless ($res && $res->next) {
        $c->response->redirect($c->uri_for('/pilots'));
        return;
    }

    $c->stash->{'pilot'} = { map { $_ => $res->{$_} } $res->columns };

    push(@{$c->stash->{'breadcrumbs'}}, { name => $res->{'name'}, link => $c->uri_for('/pilots', $pilot_id) });

    $c->stash->{'template'} = 'pilots/detail.tt2';
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
