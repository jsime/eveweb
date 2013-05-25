package EVEWeb::Controller::Login;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $username = $c->request->params->{'username'};
    my $password = $c->request->params->{'password'};

    if ($c->sessionid && $c->user_exists) {
        $c->response->redirect($c->uri_for('/'));
        return;
    }

    if ($username && $password) {
        if ($c->authenticate({ username => $username, password => $password })) {
            $c->response->redirect($c->uri_for('/'));
            return;
        } else {
            $c->stash( error_msg => "Invalid username or password.");
        }
    }

    $c->stash( template => 'login.tt2' );
}


=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
