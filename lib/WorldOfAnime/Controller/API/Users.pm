package WorldOfAnime::Controller::API::Users;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }

sub GetNewestMembers :Path('/api/members/newest') :Args(0) {
    my ( $self, $c, $type  ) = @_;

    # Redis cache client and key
    my $redis = $c->model('Redis');
    my $key   = "woa/members/newest";

    # 
    my $members;
    
    $members = $redis->client->get($key);

    if ($members) { 
        my $membersWithImages = WorldOfAnime::Controller::Helpers::Users::WeaveProfileImages( $c, $members);
        if ($type eq "code") {
        	return $membersWithImages;
        } else {
        	$c->response->body($membersWithImages);
        }
        $c->detach();
    }

	my $Members = $c->model("DB::Users")->search({
	        status => 1,
	    }, {
	    	select   => [qw/id username confirmdate/],
    	    order_by => 'confirmdate DESC',
      	    rows    => 10,
            });
	
    while (my $member = $Members->next) {
    	my $id = $member->id;
    	my $username = $member->username;
    	my $joindate = $member->confirmdate;

		push (@{ $members} , { 'id' => "$id", 'username' => "$username", 'joindate' => "$joindate" });
	}

   # Set cache for 1 day
   $redis->client->setex($key, (1 * 24 * 60 * 60), to_json($members));


    if ($members) { 
        my $membersWithImages = WorldOfAnime::Controller::Helpers::Users::WeaveProfileImages( $c, to_json($members));
        if ($type eq "code") {
        	return $membersWithImages;
        } else {        
        	$c->response->body($membersWithImages);
        }
        $c->detach();
    }

    $c->response->body("");
}

1;