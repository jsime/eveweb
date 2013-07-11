package EVEWeb::Controller::Account::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Account::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{'template'} = 'account/api/index.tt2';
}

sub add :Local :Args(0) {
    my ( $self, $c ) = @_;

    my $key_id = $c->request->params->{'key_id'} || undef;
    my $v_code = $c->request->params->{'v_code'} || undef;

    my ($res, $key);

    if ($key_id && $v_code) {
        $c->model('DB')->begin;
        $res = $c->model('DB')->do(q{
            insert into eve.api_keys
                ( user_id, key_id, v_code, active, verified )
            values
                ( ?, ?, ?, 'f', 'f' )
            returning *
        }, $c->stash->{'user'}->{'user_id'}, $key_id, $v_code);

        if ($res && $res->next) {
            $c->model('DB')->commit;
            $key = { map { $_ => $res->{$_} } $res->columns };
        } else {
            $c->model('DB')->rollback;

            $res = $c->model('DB')->do(q{
                select k.*
                from eve.api_keys k
                where k.user_id = ?
                    and k.key_id = ?
                    and k.v_code = ?
            }, $c->stash->{'user'}->{'user_id'}, $key_id, $v_code);

            if ($res && $res->next) {
                push(@{$c->stash->{'errors'}}, 'That key has already been added to your account.');
            } else {
                push(@{$c->stash->{'errors'}}, 'An error prevented that key from being added to your account. You may try again or contact site administrators.');
            }
        }
    } else {
        push(@{$c->stash->{'errors'}}, 'Both the Key ID and Verification Code are required when adding API Keys.');
    }

    if (@{$c->stash->{'errors'}} > 0) {
        $c->forward('index');
        return;
    }

    # TODO Verify Key

    $c->flash->{'message'} = 'API Key added to your account.';
    $c->response->redirect($c->uri_for('index'));
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
