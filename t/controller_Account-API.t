use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Account::API;

ok( request('/account/api')->is_success, 'Request should succeed' );
done_testing();
