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

    $c->stash->{'template'} = 'account/index.tt2';
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
