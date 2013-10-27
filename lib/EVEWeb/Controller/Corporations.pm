package EVEWeb::Controller::Corporations;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Corporations - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Corporations', link => $c->uri_for('/corporations') });
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select c.corporation_id, c.name, c.ticker, c.tax_rate, c.members, c.shares
        from eve.corporations c
            join eve.pilot_corporations pc on (pc.corporation_id = c.corporation_id)
            join eve.pilot_api_keys pk on (pk.pilot_id = pc.pilot_id)
            join eve.api_keys k on (k.key_id = pk.key_id)
        where k.user_id = ? and pc.to_datetime is null
        group by c.corporation_id, c.name, c.ticker, c.tax_rate, c.members, c.shares
        order by case when c.corporation_id between 1000002 and 1000182 then 1 else 0 end asc,
            c.name asc
    }, $c->stash->{'user'}{'user_id'});

    $c->stash->{'corporations'} = [];
    while ($res->next) {
        push(@{$c->stash->{'corporations'}}, { map { $_ => $res->{$_} } $res->columns });
    }

    $c->stash->{'template'} = 'corporations/index.tt2';
}

sub corporations : PathPart Chained('/') Args(1) {
    my ($self, $c, $corp_id) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Corporation Foobarbaz', link => $c->uri_for('/corporations', $corp_id) });

    $c->stash->{'template'} = 'corporations/detail.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
