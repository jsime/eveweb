package EVEWeb::View::Web;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        EVEWeb->path_to( 'root', 'src' ),
        EVEWeb->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    render_die   => 1,
});

=head1 NAME

EVEWeb::View::Web - Catalyst TTSite View

=head1 SYNOPSIS

See L<EVEWeb>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

