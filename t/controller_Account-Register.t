use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Account::Register;

ok( request('/account/register')->is_success, 'Request should succeed' );
done_testing();
