use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Skills;

ok( request('/skills')->is_success, 'Request should succeed' );
done_testing();
