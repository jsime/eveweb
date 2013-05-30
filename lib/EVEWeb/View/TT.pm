package EVEWeb::View::TT;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    INCLUDE_PATH => [
        EVEWeb->path_to( 'root', 'src' ),
        EVEWeb->path_to( 'root', 'lib' )
    ],
    TEMPLATE_EXTENSION => '',
    render_die => 1,
);

=head1 NAME

EVEWeb::View::TT - TT View for EVEWeb

=head1 DESCRIPTION

TT View for EVEWeb.

=head1 SEE ALSO

L<EVEWeb>

=head1 AUTHOR

Jon Sime,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
