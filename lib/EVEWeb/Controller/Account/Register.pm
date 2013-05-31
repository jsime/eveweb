package EVEWeb::Controller::Account::Register;
use Moose;
use namespace::autoclean;

use Captcha::reCAPTCHA;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

EVEWeb::Controller::Account::Register - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $captcha = Captcha::reCAPTCHA->new();

    $c->stash->{'captcha'} = $captcha->get_html(
        $c->config->{'recaptcha_api_key_public'},
        undef, undef,
        { theme => 'white' }
    );

    $c->stash->{'template'} = 'account/register/index.tt2';
}

=head2 do

Accepts registration form input. If everything (including captcha) checks
out, send verification email and display message to use to check for it.
On any failures, set flash appropriately and forward to the index method.

=cut

sub do :Local :Args(0) {
    my ($self, $c) = @_;
}

=head2 verify

Requires two path arguments: a user ID and a verification token. These must
match an outstanding user verification. If a valid pair is provided, flash
is set thanking the user for verifying their email address and we forward to
login. Otherwise we complain.

=cut

sub verify :Local :Args(2) {
    my ($self, $c, $user_id, $token) = @_;
}

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
