use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Plans;

ok( request('/plans')->is_success, 'Request should succeed' );
done_testing();
