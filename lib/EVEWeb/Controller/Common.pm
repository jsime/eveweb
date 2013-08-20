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

    if (grep { $_->{'pilot_id'} == $pilot_id } @{$c->stash->{'user'}{'pilots'}}) {
        if (exists $c->stash->{'user'}{'pilots_compare'}) {
            $c->stash->{'user'}{'pilots_compare'} = [split(',', $c->stash->{'user'}{'pilots_compare'})]
                unless ref($c->stash->{'user'}{'pilots_compare'}) eq 'ARRAY';
        } else {
            $c->stash->{'user'}{'pilots_compare'} = [];
        }

        unless (grep { $_ == $pilot_id } @{$c->stash->{'user'}{'pilots_compare'}}) {
            push(@{$c->stash->{'user'}{'pilots_compare'}}, $pilot_id);

            my $res = $c->model('DB')->do(q{
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


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
