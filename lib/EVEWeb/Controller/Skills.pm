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

    my $res = $c->model('DB')->do(q{
        select sg.skill_group_id, sg.name as skill_group_name,
            s.skill_id, s.name, s.description, s.rank,
            s.primary_attribute_id, s.secondary_attribute_id,
            a1.name as primary_attribute_name,
            a2.name as secondary_attribute_name
        from ccp.skill_groups sg
            join ccp.skills s on (s.skill_group_id = sg.skill_group_id)
            join ccp.attributes a1 on (a1.attribute_id = s.primary_attribute_id)
            join ccp.attributes a2 on (a2.attribute_id = s.secondary_attribute_id)
        where sg.published and s.published
        order by sg.name asc, s.name asc
    });

    $c->stash->{'skill_groups'} = {};

    while ($res->next) {
        my $group = $res->{'skill_group_name'};

        $c->stash->{'skill_groups'}{$group} = {
            skill_group_id   => $res->{'skill_group_id'},
            skill_group_name => $res->{'skill_group_name'},
            skills           => [],
        } unless exists $c->stash->{'skill_groups'}{$group};

        push(@{$c->stash->{'skill_groups'}{$group}{'skills'}}, { map { $_ => $res->{$_} } $res->columns });
    }

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Skills', link => $c->uri_for('/skills') });
}


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{'template'} = 'skills/index.tt2';
}

sub skills :PathPart Chained('/') Args(1) {
    my ($self, $c, $skill_id) = @_;

    my $res = $c->model('DB')->do(q{
        select s.*, sg.name as skill_group_name,
            a1.name as primary_attribute_name,
            a2.name as secondary_attribute_name
        from ccp.skills s
            join ccp.skill_groups sg on (sg.skill_group_id = s.skill_group_id)
            join ccp.attributes a1 on (a1.attribute_id = s.primary_attribute_id)
            join ccp.attributes a2 on (a2.attribute_id = s.secondary_attribute_id)
        where s.skill_id = ? and s.published and sg.published
    }, $skill_id);

    unless ($res && $res->next) {
        $c->response->redirect($c->uri_for('/skills'));
        return;
    }

    $c->stash->{'skill'} = { map { $_ => $res->{$_} } $res->columns };

    $res = $c->model('DB')->do(q{
        select t.*, s.rank, s.description,
            a1.name as primary_attribute_name,
            a2.name as secondary_attribute_name
        from ccp.skill_tree t
            join ccp.skills s on (s.skill_id = t.required_skill_id)
            join ccp.attributes a1 on (a1.attribute_id = s.primary_attribute_id)
            join ccp.attributes a2 on (a2.attribute_id = s.secondary_attribute_id)
        where t.skill_id = ?
        order by t.tier_path
    }, $skill_id);

    my @skill_ids;

    if ($res) {
        $c->stash->{'required_skills'} = [];

        while ($res->next) {
            push(@{$c->stash->{'required_skills'}}, { map { $_ => $res->{$_} } $res->columns });
            push(@skill_ids, $res->{'required_skill_id'});
        }
    }

    if (@skill_ids > 0 && @{$c->stash->{'user'}{'pilots_compare'}} > 0) {
        $res = $c->model('DB')->do(q{
            select p.pilot_id, p.name,
                tt.skill_id, tt.train_level, tt.train_points, tt.rate, tt.train_seconds,
                justify_interval(interval '1 second' * tt.train_seconds),
                ps.level as trained_level
            from plans.training_times tt
                join eve.pilots p on (p.pilot_id = tt.pilot_id)
                left join eve.pilot_skills ps on (ps.pilot_id = tt.pilot_id and ps.skill_id = tt.skill_id)
            where tt.pilot_id in ???
                and tt.skill_id in ???
        }, $c->stash->{'user'}{'pilots_compare'}, \@skill_ids);

        if ($res) {
            $c->stash->{'pilot_skills'} = {};

            while ($res->next) {
                $c->stash->{'pilot_skills'}{$res->{'pilot_id'}} = {
                    name   => $res->{'name'},
                    skills => {},
                } unless exists $c->stash->{'pilot_skills'}{$res->{'pilot_id'}};

                $c->stash->{'pilot_skills'}{$res->{'pilot_id'}}{'skills'}{$res->{'skill_id'}} = {
                    trained_level => $res->{'trained_level'},
                    rate          => $res->{'rate'},
                    train_points  => 0,
                    train_seconds => 0,
                } unless exists $c->stash->{'pilot_skills'}{$res->{'pilot_id'}}{'skills'}{$res->{'skill_id'}};

                # don't tack on numbers for what remains to be trained if they already meet the requirements
                next if $res->{'trained_level'} && $res->{'trained_level'} >= $res->{'train_level'};

                $c->stash->{'pilot_skills'}{$res->{'pilot_id'}}{'skills'}{$res->{'skill_id'}}{'train_points'}
                    += $res->{'train_points'};
                $c->stash->{'pilot_skills'}{$res->{'pilot_id'}}{'skills'}{$res->{'skill_id'}}{'train_seconds'}
                    += $res->{'train_seconds'};
            }
        }
    }

    push(@{$c->stash->{'breadcrumbs'}},
        { name => $c->stash->{'skill'}{'skill_group_name'} },
        { name => $c->stash->{'skill'}{'name'}, , link => $c->uri_for('/skills', $skill_id) },
    );

    $c->stash->{'template'} = 'skills/detail.tt2';
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
