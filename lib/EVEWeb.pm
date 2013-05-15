package EVEWeb;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use DBIx::DataStore ( config => 'yaml' );

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple

    StackTrace

    Session
    Session::State::Cookie
    Session::Store::Memcached

    Authentication
    Authentication::Credential::Password
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in eveweb.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'EVEWeb',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    default_view => 'Web',

    'Plugin::Session' => {
        cookie_domain => 'dev.ube-kosan.com',
        memcached_new_args => {
            'data'      => ['192.168.122.1:11211'],
            'namespace' => ['eveweb'],
        },
    }
);

__PACKAGE__->config->{'authentication'} = {
    'default_realm' => 'default',
    'realms' => {
        'default' => {
            'credential' => {
                'class'              => 'Password',
                'password_field'     => 'password',
                'password_type'      => 'salted_hash',
                'password_salt_len'  => 16
            },
            'store' => {
                'class'     => 'DBIx::DataStore',
                'datastore' => 'eveweb',
                #'dbh'   => 
            }
        }
    }
};

# Start the application
__PACKAGE__->setup();

=head1 NAME

EVEWeb - Catalyst based application

=head1 SYNOPSIS

    script/eveweb_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<EVEWeb::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
