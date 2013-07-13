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

    my $res = $c->model('DB')->do(q{
        select * from eve.api_keys where user_id = ? order by key_id asc
    }, $c->stash->{'user'}{'user_id'});

    $c->stash->{'keys'} = [];
    if ($res) {
        while ($res->next) {
            push(@{$c->stash->{'keys'}}, { map { $_ => $res->{$_} } $res->columns });
        }
    }

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

    # Perform remote key verification against CCP API
    my $api;
    eval { $api = Games::EVE::APIv2->new( key_id => $key->{'key_id'}, v_code => $key->{'v_code'} ) };

    if ($@) {
        push(@{$c->stash->{'errors'}}, 'The API Key you provided could not be verified. Please verify the ID and Verification Code and try again.');

        $c->forward('index');
        return;
    }

    my $key_expires = $api->expires->is_infinite ? 'infinity' : $api->expires . '+0000';

    $res = $c->model('DB')->do(q{
        update eve.api_keys
        set ???
        where user_id = ? and key_id = ? and v_code = ?
    }, {    key_type    => lc($api->key_type),
            access_mask => $api->access_mask,
            verified    => 't',
            active      => 't',
            expires_at  => $key_expires,
            updated_at  => 'now',
    }, $c->stash->{'user'}->{'user_id'}, $key_id, $v_code);

    if (!$res) {
        push(@{$c->stash->{'errors'}}, 'The API Key you provided could not be verified. Please verify the ID and Verification Code and try again.');

        $c->forward('index');
        return;
    }

    $c->flash->{'message'} = 'API Key added to your account.';
    $c->response->redirect($c->uri_for('/account/api'));
}

sub activate :Local {
    my ($self, $c, $key_id, $v_code) = @_;

    unless ($key_id && $v_code) {
        $c->response->redirect($c->uri_for('/account/api'));
        return;
    }

    my $key = $c->model('DB')->do(q{
        select k.*
        from eve.api_keys k
        where k.user_id = ?
            and k.key_id = ?
            and k.v_code = ?
    }, $c->stash->{'user'}{'user_id'}, $key_id, $v_code);

    if ($key && $key->next) {
        push(@{$c->stash->{'errors'}}, 'This key has already been activated.')
            if $key->{'active'};
        push(@{$c->stash->{'errors'}}, 'This key has not been verified.')
            unless $key->{'verified'};
    } else {
        push(@{$c->stash->{'errors'}}, 'The specified key could not be located.');
    }

    if (@{$c->stash->{'errors'}} > 0) {
        $c->forward('index');
        return;
    }

    my $res = $c->model('DB')->do(q{
        update eve.api_keys
        set ???
        where key_id = ?
    }, {
        active     => 't',
        updated_at => 'now',
    }, $key->{'key_id'});

    $c->flash->{'message'} = 'Your API Key has been activated.';
    $c->response->redirect($c->uri_for('/account/api'));
}

sub deactivate :Local {
    my ($self, $c, $key_id, $v_code) = @_;

    unless ($key_id && $v_code) {
        $c->response->redirect($c->uri_for('/account/api'));
        return;
    }

    my $key = $c->model('DB')->do(q{
        select k.*
        from eve.api_keys k
        where k.user_id = ?
            and k.key_id = ?
            and k.v_code = ?
    }, $c->stash->{'user'}{'user_id'}, $key_id, $v_code);

    if ($key && $key->next) {
        push(@{$c->stash->{'errors'}}, 'This key is already inactive.')
            unless $key->{'active'};
    } else {
        push(@{$c->stash->{'errors'}}, 'The specified key could not be located.');
    }

    if (@{$c->stash->{'errors'}} > 0) {
        $c->forward('index');
        return;
    }

    my $res = $c->model('DB')->do(q{
        update eve.api_keys
        set ???
        where key_id = ?
    }, {
        active     => 'f',
        updated_at => 'now',
    }, $key->{'key_id'});

    $c->flash->{'message'} = 'Your API Key has been de-activated.';
    $c->response->redirect($c->uri_for('/account/api'));
}

sub verify :Local {
    my ($self, $c, $key_id, $v_code) = @_;

    unless ($key_id && $v_code) {
        $c->response->redirect($c->uri_for('/account/api'));
        return;
    }

    my $api;
    eval { $api = Games::EVE::APIv2->new( key_id => $key_id, v_code => $v_code ) };

    if ($@) {
        push(@{$c->stash->{'errors'}}, 'The API Key you provided could not be verified. Please verify the ID and Verification Code and try again.');

        $c->forward('index');
        return;
    }

    my $key_expires = $api->expires->is_infinite ? 'infinity' : $api->expires . '+0000';

    my $res = $c->model('DB')->do(q{
        update eve.api_keys
        set ???
        where user_id = ? and key_id = ? and v_code = ?
    }, {    key_type    => lc($api->key_type),
            access_mask => $api->access_mask,
            verified    => 't',
            active      => 't',
            expires_at  => $key_expires,
            updated_at  => 'now',
    }, $c->stash->{'user'}->{'user_id'}, $key_id, $v_code);

    if (!$res) {
        push(@{$c->stash->{'errors'}}, 'The API Key you provided could not be verified. Please verify the ID and Verification Code and try again.');

        $c->forward('index');
        return;
    }

    $c->flash->{'message'} = 'The API Key has been verified and activated.';
    $c->response->redirect($c->uri_for('/account/api'));
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
