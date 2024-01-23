use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'WorldOfAnime' }
BEGIN { use_ok 'WorldOfAnime::Controller::DAO_Groups' }

ok( request('/dao_groups')->is_success, 'Request should succeed' );
done_testing();
