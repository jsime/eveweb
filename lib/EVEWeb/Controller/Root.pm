package EVEWeb::Controller::Root;
use Moose;
use namespace::autoclean;

use Data::Dumper;
use Games::EVE::APIv2;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

EVEWeb::Controller::Root - Root Controller for EVEWeb

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $res = $c->model('DB')->do(q{
        select p.*
        from eve.pilots p
        where p.pilot_id in ( select pk.pilot_id
                              from eve.pilot_api_keys pk
                                  join eve.api_keys k on (k.key_id = pk.key_id)
                              where k.user_id = ?
                            )
            and p.active
        order by p.name asc
    }, $c->stash->{'user'}{'user_id'});

    $c->stash->{'pilots'} = [];
    while ($res->next) {
        push(@{$c->stash->{'pilots'}}, { map { $_ => $res->{$_} } $res->columns });
    }

    $c->stash( template => 'index.tt2' );
}

=head2 auto

Enforce login requirement for all but a select number of pages (login, registration, etc.).

=cut

sub auto :Private {
    my ($self, $c) = @_;

    my @noauth_paths = qw(
        login
        account/register
        account/register/do
        account/register/verify
    );

    # Set up a couple common stash keys
    $c->stash->{'errors'} = [];
    $c->stash->{'field_errors'} = {};
    $c->stash->{'breadcrumbs'} = [];

    if (!$c->user_exists) {
        # Paths for which access is permitted to visitors not logged in
        foreach my $path (@noauth_paths) {
            return 1 if $c->request->path =~ m{^$path};
        }

        $c->response->redirect($c->uri_for('/login'));
        return 0;
    }

    my $res = $c->model('DB')->do(q{
        select * from users where user_id = ?
    }, $c->user->get('user_id'));

    die "Invalid user provided" unless $res && $res->next;

    $c->stash->{'user'} = { map { $_ => $res->{$_} } $res->columns };

    # Hardcode a user settings for timezone, datetime and date formats.
    $c->stash->{'user'}{'timezone'} = 'UTC';
    $c->stash->{'user'}{'format_date'} = 'YYYY-MM-DD';
    $c->stash->{'user'}{'format_time'} = 'HH24:MI:SS';
    $c->stash->{'user'}{'format_datetime'} = 'YYYY-MM-DD HH24:MI:SS';

    $res = $c->model('DB')->do(q{
        select pr.pref_name, pr.pref_value
        from user_prefs pr
        where pr.user_id = ?
    }, $c->stash->{'user'}{'user_id'});

    while ($res->next) {
        $c->stash->{'user'}{$res->{'pref_name'}} = $res->{'pref_value'};
    }

    return 1;
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
