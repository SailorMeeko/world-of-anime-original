use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'WorldOfAnime' }
BEGIN { use_ok 'WorldOfAnime::Controller::DAO_Games' }

ok( request('/dao_games')->is_success, 'Request should succeed' );
done_testing();
