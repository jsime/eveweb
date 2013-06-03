package EVEWeb::Controller::Account::Register;
use Moose;
use namespace::autoclean;

use Captcha::reCAPTCHA;
use Crypt::SaltedHash;
use Digest::SHA qw( sha1_hex );

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
        (exists $c->stash->{'captcha_error'} ? $c->stash->{'captcha_error'} : undef),
        undef,
        { theme => 'white' }
    );
}

=head2 do

Accepts registration form input. If everything (including captcha) checks
out, send verification email and display message to use to check for it.
On any failures, set flash appropriately and forward to the index method.

=cut

sub do :Local :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{'errors'} = [];
    $c->stash->{'field_errors'} = {};

    foreach my $fld (qw( username email password password_retype )) {
        if (!$c->request->params->{$fld} or $c->request->params->{$fld} !~ m{\w}o) {
            $c->stash->{'field_errors'}{$fld} = 1;
            $c->stash->{$fld} = '';
        } else {
            $c->stash->{$fld} = $c->request->params->{$fld} if grep { $_ eq $fld } qw( username email );
        }
    }

    push(@{$c->stash->{'errors'}}, 'Username must be at least 4 characters long.')
        if $c->stash->{'username'} =~ m{\w}o and length($c->stash->{'username'}) < 4;

    if (keys %{$c->stash->{'field_errors'}} > 0) {
        push(@{$c->stash->{'errors'}}, 'Required fields are missing.');
    }

    if ($c->request->params->{'username'} =~ m{[^a-z0-9 _-]}i) {
        push(@{$c->stash->{'errors'}}, 'Username contains invalid characters. Please limit your username to letters, numbers, spaces, dashes, and underscores.');
    }

    if ($c->request->params->{'password'} =~ m{\w}o and $c->request->params->{'password_retype'} =~ m{\w}o
            and $c->request->params->{'password'} ne $c->request->params->{'password_retype'}) {
        push(@{$c->stash->{'errors'}}, 'Password fields do not match.');
    }

    my $captcha = Captcha::reCAPTCHA->new();

    my $result = $captcha->check_answer(
        $c->config->{'recaptcha_api_key_private'},
        $c->request->address,
        $c->request->params->{'recaptcha_challenge_field'},
        $c->request->params->{'recaptcha_response_field'}
    );

    if ($result->{'is_valid'}) {
        $c->stash->{'passed_captcha'} = 1;
    } else {
        push(@{$c->stash->{'errors'}}, 'Invalid captcha response.');
        $c->stash->{'recaptcha_error'} = $result->{'error'};
    }

    if ($c->stash->{'username'} =~ m{\w}o) {
        my $res = $c->model('DB')->do(q{
            select user_id
            from public.users
            where lower(username) = lower(?)
        }, $c->stash->{'username'});

        if ($res && $res->next) {
            push(@{$c->stash->{'errors'}}, 'That username is not available.');
        }
    }

    if (!exists $c->request->params->{'terms_accept'} or lc($c->request->params->{'terms_accept'}) ne 'on') {
        push(@{$c->stash->{'errors'}}, 'You must accept the terms of service for this site before you may register an account.');
    }

    if (@{$c->stash->{'errors'}} > 0) {
        $c->forward('index');
        return;
    }

    # While I'd love to use Bcrypt here, it seems the current crop of Catalyst auth/credential
    # plugins don't quite support it (can't seem to find a way to pass cost setting in).
    my $hasher = Crypt::SaltedHash->new();
    $hasher->add($c->request->params->{'password'});

    $c->stash->{'user'} = {
        username     => $c->request->params->{'username'},
        email        => $c->request->params->{'email'},
        password     => $hasher->generate,
        verify_token => sha1_hex(rand()), # this doesn't need to be cryptographically secure, just random
    };

    my $res = $c->model('DB')->do(q{
        insert into public.users ??? returning user_id
    }, $c->stash->{'user'});

    if (!$res or !$res->next) {
        push(@{$c->stash->{'error'}}, 'An error occurred while creating your account. You may try again, but if this persists, please contact site administrators.');
    }

    if (@{$c->stash->{'errors'}} > 0) {
        $c->forward('index');
        return;
    }

    $c->stash->{'user'}{'user_id'} = $res->{'user_id'};

    $c->stash->{'email'} = {
        to       => $c->request->params->{'email'},
        from     => $c->config->{'email_from'} || 'eveweb@ube-kosan.com',
        subject  => 'Confirm your registration',
        template => 'account/verify_registration.tt2',
    };
    $c->forward($c->view('Email::Template'));

    $c->response->redirect($c->uri_for('/accout/register/verify', $res->{'user_id'}));
}

=head2 verify

Requires two path arguments: a user ID and a verification token. These must
match an outstanding user verification. If a valid pair is provided, flash
is set thanking the user for verifying their email address and we forward to
login. Otherwise we complain.

=cut

sub verify :Local {
    my ($self, $c, $user_id, $token) = @_;

    # Support both path style passing as well as POST arguments from the
    # form in case the user copies & pastes the verification token.
    $user_id = $user_id || $c->request->params->{'user_id'};
    $token   = $token   || $c->request->params->{'token'};

    if (!$user_id || $user_id !~ m{^\d+$}o) {
        # Keeping it simple for now. Just redirect to / if we don't at least
        # have a User ID.
        $c->response->redirect($c->uri_for('/'));
        return;
    }

    if ($token && $token =~ m{^[0-9a-f]+$}o) {
        my $res = $c->model('DB')->do(q{
            update public.users
            set verified = 't'
            where user_id = ? and verify_token = ? and not verified
            returning *
        }, $user_id, $token);

        if ($res && $res->next) {
            # User verified successfully. Send to account page with a flash.
            $c->flash->{'message'} = 'Your account has been verified and is now ready for use.';
            $c->response->redirect($c->uri_for('/account'));
            return;
        }

        # Reaching this point means we received a User ID and a token, but they didn't
        # match an unverified account for any number of reasons.
        $c->stash->{'errors'} = ['There was an error verifying the specified account'];
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
