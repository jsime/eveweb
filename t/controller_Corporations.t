use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Corporations;

ok( request('/corporations')->is_success, 'Request should succeed' );
done_testing();
