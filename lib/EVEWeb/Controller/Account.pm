package EVEWeb::Controller::Account;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Account - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto :Private {
    my ($self, $c) = @_;

    push(@{$c->stash->{'breadcrumbs'}}, { name => 'Account Management', link => $c->uri_for('/account') });
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select name, abbrev, utc_offset
        from pg_timezone_names
        where name not like 'posix/%'
        order by name asc
    });

    $c->stash->{'timezones'} = [];
    while ($res->next) {
        $res->{'utc_offset'} =~ m{(^-?\d+:\d+)}o;

        push(@{$c->stash->{'timezones'}},
            {   name    => $res->{'name'},
                abbrev  => $res->{'abbrev'},
                offset  => $1,
            });
    }

    $c->stash->{'time_formats'} = [];
    $c->stash->{'date_formats'} = [];

    my %format_examples;

    $res = $c->model('DB')->do(q{
        select f.format, to_char('2003-05-06 16:17:18+0000'::timestamptz at time zone 'UTC', f.format) as example
        from ( select unnest(ARRAY[???])
            ) f(format)
    }, [@{$c->config->{'datetime_formats'}{'time'}}, @{$c->config->{'datetime_formats'}{'date'}}]);

    while ($res->next) {
        $format_examples{$res->{'format'}} = $res->{'example'};
    }

    push(@{$c->stash->{'time_formats'}}, { format => $_, example => $format_examples{$_} })
        for @{$c->config->{'datetime_formats'}{'time'}};
    push(@{$c->stash->{'date_formats'}}, { format => $_, example => $format_examples{$_} })
        for @{$c->config->{'datetime_formats'}{'date'}};

    $c->stash->{'template'} = 'account/index.tt2';
}

sub update :Local {
    my ($self, $c) = @_;

    my ($res, %changes);

    $c->model('DB')->begin;

    if ($c->request->params->{'username'}) {
        $c->request->params->{'username'} =~ s{(^\s+|\s+$)}{}ogs;
        $changes{'username'} = lc($c->request->params->{'username'})
            if lc($c->request->params->{'username'}) ne lc($c->stash->{'user'}{'username'});
    }

    if ($c->request->params->{'email'}) {
        $c->request->params->{'email'} =~ s{(^\s+|\s+$)}{}ogs;
        $changes{'email'} = lc($c->request->params->{'email'})
            if lc($c->request->params->{'email'}) ne lc($c->stash->{'user'}{'email'});
    }

    if (keys %changes > 0) {
        if (exists $changes{'username'}) {
            $res = $c->model('DB')->do(q{
                select u.user_id
                from public.users u
                where lower(u.username) = lower(?)
                    and u.user_id != ?
            }, $changes{'username'}, $c->stash->{'user'}{'user_id'});

            if ($res && $res->next) {
                push(@{$c->stash->{'errors'}}, 'That username is already taken by somebody else.');
            }
        }

        if (exists $changes{'email'}) {
            $res = $c->model('DB')->do(q{
                select u.user_id
                from public.users u
                where lower(u.email) = lower(?)
                    and u.user_id != ?
            }, $changes{'email'}, $c->stash->{'user'}{'user_id'});

            if ($res && $res->next) {
                push(@{$c->stash->{'errors'}}, 'That email address is already associated with another account.');
            }
        }

        if (@{$c->stash->{'errors'}} > 0) {
            $c->model('DB')->rollback;
            $c->forward('index');
        }

        $res = $c->model('DB')->do(q{
            update public.users
            set ???
            where user_id = ?
        }, { %changes, updated_at => 'now' }, $c->stash->{'user'}{'user_id'});

        unless ($res) {
            push(@{$c->stash->{'errors'}}, 'An error occurred while updating your account.');
            $c->model('DB')->rollback;
            $c->forward('index');
        }
    }

    foreach my $pref (qw( timezone format_date format_time )) {
        $changes{$pref} = $c->request->params->{$pref}
            if $c->request->params->{$pref} && $c->request->params->{$pref} ne $c->stash->{'user'}{$pref};
    }

    if (exists $changes{'format_date'} || exists $changes{'format_time'}) {
        $changes{'format_datetime'} = sprintf('%s %s',
            $c->request->params->{'format_date'} || $c->stash->{'user'}{'format_date'},
            $c->request->params->{'format_time'} || $c->stash->{'user'}{'format_time'}
        );
    }

    foreach my $pref (qw( timezone format_date format_time format_datetime )) {
        next unless exists $changes{$pref};

        $res = $c->model('DB')->do(q{
            select * from public.user_prefs where user_id = ? and pref_name = ?
        }, $c->stash->{'user'}{'user_id'}, $pref);

        if ($res && $res->next) {
            $res = $c->model('DB')->do(q{
                update public.user_prefs
                set ???
                where user_id = ? and pref_name = ?
            }, { pref_value => $changes{$pref}, updated_at => 'now' }, $c->stash->{'user'}{'user_id'}, $pref);
        } else {
            $res = $c->model('DB')->do(q{
                insert into public.user_prefs ???
            }, {
                user_id    => $c->stash->{'user'}{'user_id'},
                pref_name  => $pref,
                pref_value => $changes{$pref},
            });
        }

        unless ($res) {
            push(@{$c->stash->{'errors'}}, 'An error occurred while updating your date/time preferences.');
            $c->model('DB')->rollback;
            $c->forward('index');
        }
    }

    $c->model('DB')->commit;
    $c->flash->{'message'} = 'Your changes have been successfully saved.';
    $c->response->redirect($c->uri_for('/account'));
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
