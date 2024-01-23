use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'WorldOfAnime' }
BEGIN { use_ok 'WorldOfAnime::Controller::Forums' }

ok( request('/forums')->is_success, 'Request should succeed' );


