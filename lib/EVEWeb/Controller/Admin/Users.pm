package EVEWeb::Controller::Admin::Users;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Admin::Users - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select u.user_id, u.email, u.username, u.verified,
            to_char(u.created_at at time zone ?, ?) as created_at,
            to_char(u.updated_at at time zone ?, ?) as updated_at,
            to_char(u.deleted_at at time zone ?, ?) as deleted_at,
            count(distinct(k.key_id)) as api_keys,
            count(distinct(p.pilot_id)) as pilots
        from public.users u
            left join eve.api_keys k on (k.user_id = u.user_id)
            left join eve.pilot_api_keys pk on (pk.key_id = k.key_id)
            left join eve.pilots p on (p.pilot_id = pk.pilot_id)
        group by u.user_id, u.email, u.username, u.verified,
            u.created_at, u.updated_at, u.deleted_at
        order by u.username asc
    });

    if ($res) {
        $c->stash->{'users'} = [];

        while ($res->next) {
            push(@{$c->stash->{'users'}}, { map { $_ => $res->{$_} } $res->columns });
        }
    }

    $c->stash->{'template'} = 'admin/users/index.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
