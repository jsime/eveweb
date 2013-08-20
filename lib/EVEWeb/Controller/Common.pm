package EVEWeb::Controller::Common;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Common - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 add_pilot_compare

Accepts a pilot ID to add to the current user's list of pilots to show
in comparison/skill tables.

=cut

sub add_pilot_compare :Local :Args(1) {
    my ($self, $c, $pilot_id) = @_;

    my $redir_to = $c->request->params->{'to'} || $c->request->referer;

    my $res = $c->model('DB')->do(q{
        select p.pilot_id
        from eve.pilots p
            join eve.pilot_api_keys pk on (pk.pilot_id = p.pilot_id)
            join eve.api_keys k on (k.key_id = pk.key_id)
        where p.pilot_id = ?
            and k.user_id = ?
    }, $pilot_id, $c->stash->{'user'}{'user_id'});

    unless ($res && $res->next) {
        $c->response->redirect($redir_to);
        return;
    }

    if (grep { $_->{'pilot_id'} == $pilot_id } @{$c->stash->{'user'}{'pilots'}}) {
        if (exists $c->stash->{'user'}{'pilots_compare'}) {
            $c->stash->{'user'}{'pilots_compare'} = [split(',', $c->stash->{'user'}{'pilots_compare'})]
                unless ref($c->stash->{'user'}{'pilots_compare'}) eq 'ARRAY';
        } else {
            $c->stash->{'user'}{'pilots_compare'} = [];
        }

        unless (grep { $_ == $pilot_id } @{$c->stash->{'user'}{'pilots_compare'}}) {
            push(@{$c->stash->{'user'}{'pilots_compare'}}, $pilot_id);

            $res = $c->model('DB')->do(q{
                update public.user_prefs
                set ???
                where user_id = ?
                    and pref_name = 'pilots_compare'
            }, {
                pref_value => join(',', @{$c->stash->{'user'}{'pilots_compare'}}),
                updated_at => 'now',
            }, $c->stash->{'user'}{'user_id'});

            if ($res && $res->count < 1) {
                $res = $c->model('DB')->do(q{
                    insert into public.user_prefs ???
                }, {
                    user_id    => $c->stash->{'user'}{'user_id'},
                    pref_name  => 'pilots_compare',
                    pref_value => join(',', @{$c->stash->{'user'}{'pilots_compare'}}),
                });
            }
        }
    }

    $c->response->redirect($redir_to);
}

=head2 remove_pilot_compare

Accepts a pilot ID to remove from the current user's list of pilots to show
in comparison/skill tables.

=cut

sub remove_pilot_compare :Local :Args(1) {
    my ($self, $c, $pilot_id) = @_;

    my $redir_to = $c->request->params->{'to'} || $c->request->referer;

    my @pilot_ids = grep { $_ != $pilot_id } @{$c->stash->{'user'}{'pilots_compare'}};

    my $res;

    if (@pilot_ids > 0) {
        $res = $c->model('DB')->do(q{
            update public.user_prefs
            set pref_value = ?,
                updated_at = now()
            where user_id = ?
                and pref_name = 'pilots_compare'
        }, join(',', @pilot_ids), $c->stash->{'user'}{'user_id'});
    } else {
        $res = $c->model('DB')->do(q{
            delete from public.user_prefs
            where user_id = ?
                and pref_name = 'pilots_compare'
        }, $c->stash->{'user'}{'user_id'});
    }

    warn $res->error unless $res;

    $c->response->redirect($redir_to);
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
