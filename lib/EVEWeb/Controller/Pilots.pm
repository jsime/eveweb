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

    $c->stash->{'user'}{'pilot_list_layout'} = 'large' unless exists $c->stash->{'user'}{'pilot_list_layout'};

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Pilots', link => $c->uri_for('/pilots') });

    $c->stash->{'layouts'} = [
        { name => 'List', link => $c->uri_for('/pilots', { layout => 'list' }) },
        { name => 'Grid', link => $c->uri_for('/pilots', { layout => 'grid' }) },
    ];
}


=head2 index

=cut

sub index :Path Args(0) {
    my ( $self, $c ) = @_;

    my ($res);

    if (exists $c->request->params->{'layout'}) {
        my $layout = lc($c->request->params->{'layout'});

        if ($layout =~ m{^(list|grid)$}o) {
            $c->stash->{'user'}{'pilot_list_layout'} = $layout;

            $res = $c->model('DB')->do(q{
                update public.user_prefs
                set pref_value = ?,
                    updated_at = now()
                where user_id = ? and pref_name = 'pilot_list_layout'
            }, $layout, $c->stash->{'user'}{'user_id'});

            if ($res && $res->count < 1) {
                $res = $c->model('DB')->do(q{
                    insert into public.user_prefs ???
                }, {
                    user_id    => $c->stash->{'user'}{'user_id'},
                    pref_name  => 'pilot_list_layout',
                    pref_value => $layout,
                });
            }
        }
    }

    $res = $c->model('DB')->do(q{
        select p.*,
            c.corporation_id, c.name as corporation_name, c.ticker,
            s.skill_id, s.name as skill_name, sq.level as skill_level,
            to_char(sq.end_time at time zone ?, ?) as skill_end_time,
            sq.end_time as skill_end_time_js
        from eve.pilots p
            left join eve.pilot_corporations pc on (pc.pilot_id = p.pilot_id)
            left join eve.corporations c on (c.corporation_id = pc.corporation_id)
            left join plans.skill_queues sq on (sq.pilot_id = p.pilot_id and sq.position = 0)
            left join ccp.skills s on (s.skill_id = sq.skill_id)
        where p.pilot_id in ( select pk.pilot_id
                              from eve.pilot_api_keys pk
                                  join eve.api_keys k on (k.key_id = pk.key_id)
                              where k.user_id = ?
                            )
            and pc.to_datetime is null
        order by p.name asc
    }, $c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}, $c->stash->{'user'}{'user_id'});

    $c->stash->{'all_pilots'}      = [];
    $c->stash->{'active_pilots'}   = [];
    $c->stash->{'inactive_pilots'} = [];
    while ($res->next) {
        push(@{$c->stash->{'all_pilots'}}, { map { $_ => $res->{$_} } $res->columns });

        push(@{$c->stash->{'active_pilots'}},   $c->stash->{'all_pilots'}[-1]) if  $res->{'active'};
        push(@{$c->stash->{'inactive_pilots'}}, $c->stash->{'all_pilots'}[-1]) if !$res->{'active'};
    }

    $c->stash->{'template'} = 'pilots/index.tt2';
}

sub pilots : PathPart Chained('/') Args(1) {
    my ($self, $c, $pilot_id) = @_;

    my $res = $c->model('DB')->do(q{
        select p.*,
            c.corporation_id, c.name as corporation_name, c.ticker as corporation_ticker
        from eve.pilots p
            left join eve.pilot_corporations pc on (pc.pilot_id = p.pilot_id and pc.to_datetime is null)
            left join eve.corporations c on (c.corporation_id = pc.corporation_id)
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

sub toggle_active :Local :Args(0) {
    my ($self, $c) = @_;

    my $pilot_id = $c->request->params->{'pilot_id'};

    unless ($pilot_id) {
        $c->response->redirect($c->uri_for('/pilots'));
        return;
    }

    my $res = $c->model('DB')->do(q{
        select p.active
        from eve.pilots p
            join eve.pilot_api_keys pk on (pk.pilot_id = p.pilot_id)
            join eve.api_keys k on (k.key_id = pk.key_id)
        where p.pilot_id = ?
            and k.user_id = ?
    }, $pilot_id, $c->stash->{'user'}{'user_id'});

    unless ($res && $res->next) {
        $c->response->redirect($c->uri_for('/pilots', $pilot_id));
        return;
    }

    $res = $c->model('DB')->do(q{
        update eve.pilots
        set active = ?
        where pilot_id = ?
    }, ($res->{'active'} ? 'f' : 't'), $pilot_id);

    $c->response->redirect($c->uri_for('/pilots', $pilot_id));
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
