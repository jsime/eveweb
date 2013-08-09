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
            s.primary_attribute_id, s.secondary_attribute_id
        from ccp.skill_groups sg
            join ccp.skills s on (s.skill_group_id = sg.skill_group_id)
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
        select s.*, sg.name as skill_group_name
        from ccp.skills s
            join ccp.skill_groups sg on (sg.skill_group_id = s.skill_group_id)
        where s.skill_id = ? and s.published and sg.published
    }, $skill_id);

    unless ($res && $res->next) {
        $c->response->redirect($c->uri_for('/skills'));
        return;
    }

    $c->stash->{'skill'} = { map { $_ => $res->{$_} } $res->columns };

    $res = $c->model('DB')->do(q{
        select *
        from ccp.skill_tree
        where skill_id = ?
        order by tier_path
    }, $skill_id);

    if ($res) {
        $c->stash->{'required_skills'} = [];

        while ($res->next) {
            push(@{$c->stash->{'required_skills'}}, { map { $_ => $res->{$_} } $res->columns });
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
