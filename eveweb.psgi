use strict;
use warnings;

use EVEWeb;

my $app = EVEWeb->apply_default_middlewares(EVEWeb->psgi_app);
$app;

