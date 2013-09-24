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

    my $res = $c->model('DB')->do(q{
        select pl.*
        from plans.plans pl
        where pl.user_id = ?
        order by pl.name asc, pl.created_at asc
    }, $c->stash->{'user'}{'user_id'});

    if ($res) {
        $c->stash->{'plans'}{'personal'} = [];

        while ($res->next) {
            push(@{$c->stash->{'plans'}{'personal'}}, { map { $_ => $res->{$_} } $res->columns });
        }
    }

    $c->stash->{'template'} = 'plans/index.tt2';
}

sub add :Local {
    my ($self, $c) = @_;

    my $res = $c->model('DB')->do(q{
        insert into plans.plans
            (user_id, name)
        values (
            1,
            'Untitled ' || coalesce((select cast(regexp_replace(name, '\D+', '') as integer) + 1 as num
                                     from plans.plans
                                     where user_id = ?
                                         and name ilike 'Untitled %'
                                     order by 1 desc
                                     limit 1), 1)
        )
    }, $c->stash->{'user'}{'user_id'});

    $c->response->redirect($c->uri_for('/plans'));
}

sub delete : Local Args(1) {
    my ($self, $c, $plan_id) = @_;

    my $res = $c->model('DB')->do(q{
        delete from plans.plans
        where plans.user_id = ?
            and plans.plan_id = ?
        returning *
    }, $c->stash->{'user'}{'user_id'}, $plan_id);

    if ($res && $res->next) {
        $c->flash->{'message'} = sprintf('The plan <em>%s</em> has been deleted.', $res->{'name'});
        $c->response->redirect($c->uri_for('/plans'));
        return;
    }

    $c->flash->{'error'} = sprintf('An error occurred when attempted to delete the specified plan.');
    $c->response->redirect($c->uri_for('/plans'));
    return;
}

sub update : Local Args(1) {
    my ($self, $c, $plan_id) = @_;

    my $plan = $c->model('DB')->do(q{
        select p.*
        from plans.plans p
        where p.plan_id = ?
    }, $plan_id);

    unless ($plan && $plan->next) {
        $c->response->redirect($c->uri_for('/plans'));
        return;
    }

    unless ($c->stash->{'user'}{'user_id'} == $plan->{'user_id'}) {
        $c->flash->{'message'} = 'You are not the owner of this plan and are not allowed to update it.';
        $c->response->redirect($c->uri_for('/plans', $plan->{'plan_id'}));
        return;
    }

    my %new_plan;

    foreach my $fld (qw( name summary )) {
        if (exists $c->request->params->{$fld} && $c->request->params->{$fld} ne $plan->{$fld}) {
            $new_plan{$fld} = $c->request->params->{$fld};
        }
    }

    if (exists $c->request->params->{'pilot_id'} && $c->request->params->{'pilot_id'} != $plan->{'pilot_id'}) {
        my $pilot = $c->model('DB')->do(q{
            select p.*
            from eve.pilots p
                join eve.user_pilots up on (up.pilot_id = p.pilot_id)
            where up.user_id = ?
                and up.pilot_id = ?
        }, $c->stash->{'user'}{'user_id'}, $c->request->params->{'pilot_id'});

        if ($pilot && $pilot->next) {
            $new_plan{'pilot_id'} = $pilot->{'pilot_id'};
        } else {
            $c->response->redirect($c->uri_for('/plans', $plan->{'plan_id'}));
            return;
        }
    }

    if (keys %new_plan > 0) {
        $new_plan{'updated_at'} = 'now';

        my $res = $c->model('DB')->do(q{
            update plans.plans set ??? where plan_id = ?
        }, \%new_plan, $plan->{'plan_id'});

        if ($res) {
            $c->flash->{'message'} = 'Your changes have been saved.';
        } else {
            $c->flash->{'message'} = 'An error occurred while saving your changes.';
        }
    }

    $c->response->redirect($c->uri_for('/plans', $plan->{'plan_id'}));
    return;
}

sub plans : PathPart Chained('/') Args(1) {
    my ($self, $c, $plan_id) = @_;

    my $res = $c->model('DB')->do(q{
        select pl.*
        from plans.plans pl
        where pl.plan_id = ?
    }, $plan_id);

    unless ($res && $res->next) {
        $c->response->redirect($c->uri_for('/plans'));
        return;
    }

    $c->stash->{'plan'} = { map { $_ => $res->{$_} } $res->columns };

    push(@{$c->stash->{'breadcrumbs'}},
        { name => $c->stash->{'plan'}{'name'},
          link => $c->uri_for('/plans', $c->stash->{'plan'}{'plan_id'}),
        });

    $res = $c->model('DB')->do(q{
        select c.corporation_id, c.name as corporation_name,
            a.alliance_id, a.name as alliance_name
        from eve.user_pilots up
            left join eve.pilot_corporations pc on (pc.pilot_id = up.pilot_id and pc.to_datetime is null)
            left join eve.corporations c on (c.corporation_id = pc.corporation_id)
            left join eve.alliance_corporations ac on (ac.corporation_id = c.corporation_id and ac.to_datetime is null)
            left join eve.alliances a on (a.alliance_id = ac.alliance_id)
        where up.user_id = ?
        group by c.corporation_id, c.name, a.alliance_id, a.name
    }, $c->stash->{'user'}{'user_id'});

    if ($res) {
        $c->stash->{'corporations'} = {};
        $c->stash->{'alliances'} = {};

        while ($res->next) {
            $c->stash->{'corporations'}{$res->{'corporation_id'}} = {
                corporation_id => $res->{'corporation_id'},
                name           => $res->{'corporation_name'},
            };

            $c->stash->{'alliances'}{$res->{'alliance_id'}} = {
                alliance_id => $res->{'alliance_id'},
                name        => $res->{'alliance_name'},
            } if exists $res->{'alliance_id'} && $res->{'alliance_id'};
        }
    }

    $c->stash->{'template'} = 'plans/detail.tt2';
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
