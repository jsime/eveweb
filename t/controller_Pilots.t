use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Pilots;

ok( request('/pilots')->is_success, 'Request should succeed' );
done_testing();
