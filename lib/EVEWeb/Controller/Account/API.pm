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

sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'API Keys', link => $c->uri_for('/account/api') });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select k.user_id, k.key_id, k.v_code, k.access_mask,
            k.key_type, k.active, k.verified,
            to_char(k.created_at at time zone ?, ?) as created_at,
            to_char(k.updated_at at time zone ?, ?) as updated_at,
            to_char(k.expires_at at time zone ?, ?) as expires_at
        from eve.api_keys k
        where k.user_id = ?
        order by k.key_id asc
    }, ($c->stash->{'user'}{'timezone'}, $c->stash->{'user'}{'format_datetime'}) x 3,
        $c->stash->{'user'}{'user_id'});

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

    $key_id =~ s{(^\s+|\s+$)}{}ogs if $key_id;
    $v_code =~ s{(^\s+|\s+$)}{}ogs if $v_code;

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
                push(@{$c->stash->{'errors'}}, 'An error prevented that key from being added to your account.');
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
        push(@{$c->stash->{'errors'}}, 'The API Key you provided could not be verified.');

        $c->forward('index');
        return;
    }

    my $key_expires = $api->key->expires->is_infinite ? 'infinity' : $api->key->expires . '+0000';

    $res = $c->model('DB')->do(q{
        update eve.api_keys
        set ???
        where key_id = ?
    }, {    key_type    => lc($api->key->type),
            access_mask => $api->key->mask,
            verified    => 't',
            active      => 't',
            expires_at  => $key_expires,
            updated_at  => 'now',
    }, $key_id);

    if (!$res) {
        push(@{$c->stash->{'errors'}}, 'The API Key you provided could not be verified.');

        $c->forward('index');
        return;
    }

    $self->import_characters($c, $api);

    my $job = EVEWeb::Job->new(
        db     => $c->model('DB'),
        type   => 'key',
        stash  => { key_id => $api->key->key_id },
        run_at => DateTime->now()->add( minutes => 30 ),
    );
    $job->save;

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

    my $job = EVEWeb::Job->new(
        db     => $c->model('DB'),
        type   => 'key',
        stash  => { key_id => $key->{'key_id'} },
        run_at => DateTime->now(),
    );
    $job->save;

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

    my $key_expires = $api->key->expires->is_infinite ? 'infinity' : $api->key->expires . '+0000';

    my $res = $c->model('DB')->do(q{
        update eve.api_keys
        set ???
        where key_id = ?
    }, {    key_type    => lc($api->key->type),
            access_mask => $api->key->mask,
            verified    => 't',
            active      => 't',
            expires_at  => $key_expires,
            updated_at  => 'now',
    }, $key_id);

    if (!$res) {
        push(@{$c->stash->{'errors'}}, 'The API Key you provided could not be verified.');

        $c->forward('index');
        return;
    }

    $self->import_characters($c, $api);

    my $job = EVEWeb::Job->new(
        db     => $c->model('DB'),
        type   => 'key',
        stash  => { key_id => $api->key->key_id },
        run_at => DateTime->now()->add( minutes => 30 ),
    );
    $job->save;

    $c->flash->{'message'} = 'The API Key has been verified and activated.';
    $c->response->redirect($c->uri_for('/account/api'));
}

sub import_characters :Private {
    my ($self, $c, $api) = @_;

    my ($res);

    CHARACTER:
    foreach my $char ($api->characters) {
        $c->model('DB')->begin;

        my $job;
        eval {
            $job = EVEWeb::Job->new(
                db     => $c->model('DB'),
                type   => 'pilot',
                stash  => { pilot_id => $char->character_id },
                run_at => $char->cached_until || DateTime->now->add( minutes => 30 ),
            );
        };

        if ($@) {
            $c->model('DB')->rollback;
            next CHARACTER;
        }

        my $pilot = $c->model('DB')->do(q{
            select p.*
            from eve.pilots p
            where p.pilot_id = ?
        }, $char->character_id);

        if ($pilot && $pilot->next) {
            $res = $c->model('DB')->do(q{
                select k.api_key_id
                from eve.api_keys k
                    join eve.pilot_api_keys pk on (pk.key_id = k.key_id)
                where p.pilot_id = ?
                    and k.user_id = ?
                    and k.key_id = ?
                    and k.v_code = ?
            }, $pilot->{'pilot_id'}, $c->stash->{'user'}{'user_id'}, $api->key->key_id, $api->key->v_code);

            if ($res && $res->next) {
                $c->model('DB')->rollback;
                next CHARACTER;
            }

            $res = $c->model('DB')->do(q{
                insert into eve.pilot_api_keys
                    ( pilot_id, key_id )
                values
                    ( ?, ? )
            }, $pilot->{'pilot_id'}, $api->key->key_id);

            if ($res) {
                eval { $job->save };

                if ($@) {
                    $c->model('DB')->rollback;
                } else {
                    $c->model('DB')->commit;
                }
            } else {
                $c->model('DB')->rollback;
            }

            next CHARACTER;
        }

        $pilot = $c->model('DB')->do(q{
            insert into eve.pilots ??? returning pilot_id
        }, {
            pilot_id     => $char->character_id,
            name         => $char->name,
            race         => $char->race,
            bloodline    => $char->bloodline,
            ancestry     => $char->ancestry,
            gender       => $char->gender,
            birthdate    => $char->dob . '+0000',
            balance      => $char->balance,
            sec_status   => $char->security_status,
            cached_until => $char->cached_until . '+0000',
        });

        if ($pilot && $pilot->next) {
            $res = $c->model('DB')->do(q{
                insert into eve.pilot_api_keys
                    ( pilot_id, key_id )
                values
                    ( ?, ? )
            }, $pilot->{'pilot_id'}, $api->key->key_id);

            eval { $job->save };

            if ($@) {
                $c->model('DB')->rollback;
            } else {
                $c->model('DB')->commit;
            }
        } else {
            $c->model('DB')->rollback;
        }
    }
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
