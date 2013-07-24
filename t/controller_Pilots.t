use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Pilot;

ok( request('/pilot')->is_success, 'Request should succeed' );
done_testing();
