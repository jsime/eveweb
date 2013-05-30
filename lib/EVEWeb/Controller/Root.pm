package EVEWeb::Controller::Root;
use Moose;
use namespace::autoclean;

use Data::Dumper;

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

    $c->stash( template => 'index.tt2' );
}

=head2 auto

Enforce login requirement for all but a select number of pages (login, registration, etc.).

=cut

sub auto :Private {
    my ($self, $c) = @_;

    # Paths for which access is permitted to visitors not logged in
    foreach my $path (qw( login account/register )) {
        return 1 if $c->request->path eq $path;
    }

    if (!$c->user_exists) {
        $c->response->redirect($c->uri_for('/login'));
        return 0;
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
