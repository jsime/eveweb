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

sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Users', link => $c->uri_for('/admin/users') });
}

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
            count(distinct(p.pilot_id)) as pilots,
            array_agg(distinct(r.role_name)) as roles
        from public.users u
            left join eve.api_keys k on (k.user_id = u.user_id)
            left join eve.pilot_api_keys pk on (pk.key_id = k.key_id)
            left join eve.pilots p on (p.pilot_id = pk.pilot_id)
            left join public.user_roles ur on (ur.user_id = u.user_id)
            left join public.roles r on (r.role_id = ur.role_id)
        group by u.user_id, u.email, u.username, u.verified,
            u.created_at, u.updated_at, u.deleted_at
        order by u.username asc
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 3);

    if ($res) {
        $c->stash->{'users'} = [];

        while ($res->next) {
            push(@{$c->stash->{'users'}}, { map { $_ => $res->{$_} } $res->columns });
        }
    }

    $c->stash->{'template'} = 'admin/users/index.tt2';
}

sub edit : Local Args(1) {
    my ($self, $c, $user_id) = @_;

    my $res = $c->model('DB')->do(q{
        select u.*
        from public.users u
        where u.user_id = ?
    }, $user_id);

    unless ($res && $res->next) {
        $c->response->redirect($c->uri_for('/admin/users'));
        return;
    }

    $c->stash->{'edit_user'} = { map { $_ => $res->{$_} } $res->columns };

    $res = $c->model('DB')->do(q{
        select p.pref_name, p.pref_value,
            to_char(p.created_at at time zone ?, ?) as created_at,
            to_char(p.updated_at at time zone ?, ?) as updated_at
        from public.user_prefs p
        where p.user_id = ?
        order by p.pref_name asc
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 2,
        $c->stash->{'edit_user'}{'user_id'}
    );

    if ($res) {
        $c->stash->{'edit_user'}{'preferences'} = [];

        while ($res->next) {
            push(@{$c->stash->{'edit_user'}{'preferences'}}, { map { $_ => $res->{$_} } $res->columns });
        }
    }

    $res = $c->model('DB')->do(q{
        select k.key_id, k.key_type, k.access_mask, k.active, k.verified,
            to_char(k.expires_at at time zone ?, ?) as expires_at,
            to_char(k.created_at at time zone ?, ?) as created_at,
            to_char(k.updated_at at time zone ?, ?) as updated_at
        from eve.api_keys k
        where k.user_id = ?
        order by k.key_id asc
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 3,
        $c->stash->{'edit_user'}{'user_id'}
    );

    if ($res) {
        $c->stash->{'edit_user'}{'keys'} = [];

        while ($res->next) {
            push(@{$c->stash->{'edit_user'}{'keys'}}, { map { $_ => $res->{$_} } $res->columns });
        }
    }

    push(@{$c->stash->{'breadcrumbs'}},
        { name => $c->stash->{'edit_user'}{'username'},
          link => $c->uri_for('/admin/users/edit', $c->stash->{'edit_user'}{'user_id'}),
        });

    $c->stash->{'template'} = 'admin/users/edit.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
