use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Common;

ok( request('/common')->is_success, 'Request should succeed' );
done_testing();
