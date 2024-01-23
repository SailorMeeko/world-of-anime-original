package WorldOfAnime::Controller::API::Friends;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }

sub GetFriends :Path('/api/friends/get_friends') :Args(1) {
    my ( $self, $c, $username ) = @_;

    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByUsername($c, $username);

    # If no user, return nothing
    return $c->response->body("") unless (defined($User));

    my $id = $User->id;

    # Redis cache client and key
    my $redis = $c->model('Redis');
    my $key   = "woa/friends/$id";

    # 
    my $friends;
    
    $friends = $redis->client->get($key);

    if ($friends) { 
        my $friendsWithImages = WorldOfAnime::Controller::Helpers::Users::WeaveProfileImages( $c, $friends);
        $c->response->body($friendsWithImages);
        $c->detach();
    }

    my %SeenFriend;
    my $UserFriends = $c->model("DB::UserFriends")->search_literal("user_id = $id AND status = 2",
        {
            select   => [qw/friend_user_id modifydate/],
            distinct => 1,
    	    order_by => 'modifydate DESC',
        });    

        while (my $friend = $UserFriends->next) {
            next if $SeenFriend{$friend->friends->id};
	        my $friend_id = $friend->friends->id;
	        my $friend_name = $friend->friends->username;
	        my $friend_email = $friend->friends->email;
    
	        $SeenFriend{$friend->friends->id} = 1;
    
	        push (@{ $friends} , { 'id' => "$friend_id", 'name' => "$friend_name", 'email' => "$friend_email" });
        }


   # Set cache for 30 days
   $redis->client->setex($key, 2592000, to_json($friends));


    if ($friends) { 
        my $friendsWithImages = WorldOfAnime::Controller::Helpers::Users::WeaveProfileImages( $c, to_json($friends));        
        $c->response->body($friendsWithImages);
        $c->detach();
    }

    $c->response->body("");
}

1;