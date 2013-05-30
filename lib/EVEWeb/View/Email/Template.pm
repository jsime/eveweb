package EVEWeb::View::Email::Template;

use strict;
use base 'Catalyst::View::Email::Template';

__PACKAGE__->config(
    stash_key       => 'email',
    template_prefix => ''
);

=head1 NAME

EVEWeb::View::Email::Template - Templated Email View for EVEWeb

=head1 DESCRIPTION

View for sending template-generated email from EVEWeb. 

=head1 AUTHOR

Jon Sime,,,

=head1 SEE ALSO

L<EVEWeb>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
