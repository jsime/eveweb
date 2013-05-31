use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Account;

ok( request('/account')->is_success, 'Request should succeed' );
done_testing();
