use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Admin;

ok( request('/admin')->is_success, 'Request should succeed' );
done_testing();
