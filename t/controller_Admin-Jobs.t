use strict;
use warnings;
use Test::More;


use Catalyst::Test 'EVEWeb';
use EVEWeb::Controller::Admin::Jobs;

ok( request('/admin/jobs')->is_success, 'Request should succeed' );
done_testing();
