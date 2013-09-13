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
            amd plans.plan_id = ?
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
