package WorldOfAnime::Controller::DAO_Friends;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN { extends 'Catalyst::Controller'; }


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched WorldOfAnime::Controller::DAO_Friends in DAO_Friends.');
}


sub GetFriends_JSON :Local :Args(1) {
    my ( $c, $id ) = @_;
    my $friends;
    
    my $cid = "worldofanime:friends:$id";
    $friends = $c->cache->get($cid);

    unless ($friends) {
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

	
	# Set memcached object for 30 days
	$c->cache->set($cid, $friends, 2592000);

    }
    
    if ($friends) { return to_json($friends); }
}


# Note - memcached string needs to be cleared whenever a person adds or removes a friend
# - also whenever a person updates their notifications preferences, their memcached string needs to be recalculated,
#   along with all of their friends'


sub CalcFriends :Local :Args(1) {
    my ( $c, $id ) = @_;
    my $friends;
    
    my $cid = "worldofanime:friends:$id";    

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

	
    # Set memcached object for 30 days
    $c->cache->set($cid, $friends, 2592000);
}



sub GetFriendIDs :Local {
    my ( $c, $UserID, $n, $searchString ) = @_;
    my @FriendIDs;
    my $FriendString;
    my %SeenFriend;

    $n = "0" unless ($n);

    my $cid = "worldofanime:friend_ids:$UserID:$n";
    $FriendString = $c->cache->get($cid);
    
    unless ($FriendString) {
        my $count = 0;

        my $UserFriends = $c->model("DB::UserFriends")->search_literal("user_id = $UserID AND status = 2",
        {
            select   => [qw/friend_user_id modifydate/],
            distinct => 1,
    	    order_by => 'modifydate DESC',
        });    

        while (my $friend = $UserFriends->next) {
            next if $SeenFriend{$friend->friends->id};
            next if (($n > 0) && ($count >= $n));
            push (@FriendIDs, $friend->friends->id);
            $SeenFriend{$friend->friends->id} = 1;
            $count++;
        }
    
        foreach my $f (@FriendIDs) {
            $FriendString .= "'$f',";
        }
        $FriendString =~ s/,$//;
        
        # Set memcached object for 30 days
	$c->cache->set($cid, $FriendString, 2592000);
    }
    
    # If we have a searchString, we need to filter the $FriendString
    
    if ($searchString) {
	my $count = 0;
	my $newFriendString;
	
	my @FilterFriends = split(/,/, $FriendString);
	foreach my $f (@FilterFriends) {
	    $f =~ s/'//g;
	    my $p = $c->model('Users::UserProfile');
	    $p->build( $c, $f );
    
	    if ( ($p->username =~ /$searchString/i) ||
		 ($p->name =~ /$searchString/i) ) {
		    $newFriendString .= "'$f',";
		    $count++;
	    }
	}
	
	$newFriendString =~ s/,$//;
	$FriendString = $newFriendString;
	
	WorldOfAnime::Controller::DAO_Searches::RecordSearch( $c, 3, $searchString, $count );
    }
    
    return $FriendString;    
}


sub GetNumFriends :Local {
    my ( $c, $UserID ) = @_;
    my $NumFriends;
    my $count;
    my %SeenFriend;
    
    my $cid = "worldofanime:num_friends:$UserID";
    $NumFriends = $c->cache->get($cid);
    
    unless ($NumFriends) {

        my $UserFriends = $c->model("DB::UserFriends")->search_literal("user_id = $UserID AND status = 2 AND friend_user_id > 0",
        {
            select   => [qw/friend_user_id modifydate/],
            distinct => 1,
    	    order_by => 'modifydate DESC',
        });
        
        if ($UserFriends) {
            while (my $friend = $UserFriends->next) {
                next if $SeenFriend{$friend->friends->id};
                $SeenFriend{$friend->friends->id} = 1;
                $count++;
            }    
        }
        
        $NumFriends = $count;
        
        # Set memcached object for 30 days
	$c->cache->set($cid, $NumFriends, 2592000);        
    }
    
    return $NumFriends;
}



sub GetFriendStatus :Local {
    my ( $c, $user1, $user2, $returnDate ) = @_;
    my $status = 0; # Assume not friends
    my $friend_date;
    
    return 0 unless ($user1 && $user2); # Return 0 if we aren't even checking 2 real people
    return 2 if ($user1 == $user2); # We'll always assume people are friends with themselves
    
    # For memcached, we'll always put the lower id friend first, since it doesn't matter which order their friendship was created
    
    if ($user2 < $user1) {
	my $t = $user1;
	$user1 = $user2;
	$user2 = $t;
    }
    
    # Check memcached
    my $cid = "worldofanime:friend_status:$user1:$user2";
    my $cidDate = "worldofanime:friend_date:$user1:$user2";
    $status = $c->cache->get($cid);
    $friend_date = $c->cache->get($cidDate);
    
    unless (defined($status)) {
	
	# Status of user1 <=> user2 should always be the same as user2 <=> user1
	# This is only until I fix the badly designed friends table
	
	my $Friends = $c->model("DB::UserFriends")->search({
	    -or => [
		-and => [
		    user_id => $user1,
		    friend_user_id => $user2,
		],
		-and => [
		    user_id => $user2,
		    friend_user_id => $user1,
		],				
	    ]
        });
	
	if ($Friends) {
	    # We have to use search, and get next because there could potentially be more than one entry
	    # Again, fix in later friend table design
	    
	    my $f = $Friends->next;
	    if ($f) {
		$status = $f->status;
		$friend_date = $f->modifydate;
	    }
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, $status, 2592000);
	$c->cache->set($cidDate, $friend_date, 2592000);
    }
    


    
    if ($returnDate && !($friend_date)) {
	# This shouldn't happen, but in case it does, lets handle it...
	# Status of user1 <=> user2 should always be the same as user2 <=> user1
	# This is only until I fix the badly designed friends table
	
	my $Friends = $c->model("DB::UserFriends")->search({
	    -or => [
		-and => [
		    user_id => $user1,
		    friend_user_id => $user2,
		],
		-and => [
		    user_id => $user2,
		    friend_user_id => $user1,
		],				
	    ]
        });
	
	if ($Friends) {
	    # We have to use search, and get next because there could potentially be more than one entry
	    # Again, fix in later friend table design
	    
	    my $f = $Friends->next;
	    if ($f) {
		$status = $f->status;
		$friend_date = $f->modifydate;
	    }
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, $status, 2592000);
	$c->cache->set($cidDate, $friend_date, 2592000);
    }
    
    
    if ($returnDate) {
	return ($status, $friend_date);
    } else {
	return ($status);
    }
}



# Perform post-Post cleanup
sub FriendCleanupChange :Local {
    my ( $c, $UserID ) = @_;
    
    $c->cache->remove("worldofanime:friends:$UserID");
    $c->cache->remove("worldofanime:friend_ids:$UserID");
    $c->cache->remove("worldofanime:num_friends:$UserID");
    $c->cache->remove("worldofanime:num_friend_requests:$UserID");    
    $c->cache->remove("worldofanime:friend_html:$UserID");
    $c->cache->remove("worldofanime:friend_html_mini:$UserID");
    $c->cache->remove("worldofanime:friend_ids:$UserID:0");

    my $redis = $c->model('Redis');
    $redis->client->del("woa/friends/$UserID");
}

sub FriendStatusChange :Local {
    my ( $c, $user1, $user2 ) = @_;
    
    # For memcached, we'll always put the lower id friend first, since it doesn't matter which order their friendship was created
    
    if ($user2 < $user1) {
	my $t = $user1;
	$user1 = $user2;
	$user2 = $t;
    }
    
    $c->cache->remove("worldofanime:friend_status:$user1:$user2");
    $c->cache->remove("worldofanime:friend_date:$user1:$user2");
}

__PACKAGE__->meta->make_immutable;

1;
