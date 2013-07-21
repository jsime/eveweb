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
        select f.format, to_char(now(), f.format) as example
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

    my %changes;

    if ($c->params->{'username'}) {
        $c->params->{'username'} =~ s{(^\s+|\s+$)}{}ogs;
        $changes{'username'} = lc($c->params->{'username'})
            if lc($c->params->{'username'}) ne lc($c->stash->{'user'}{'username'});
    }

    if ($c->params->{'email'}) {
        $c->params->{'email'} =~ s{(^\s+|\s+$)}{}ogs;
        $changes{'email'} = lc($c->params->{'email'})
            if lc($c->params->{'email'}) ne lc($c->stash->{'user'}{'email'});
    }

    my $timezone = $c->params->{'timezone'}
        if $c->params->{'timezone'}
        && $c->params->{'timezone'} ne $c->stash->{'user'}{'timezone'};
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
