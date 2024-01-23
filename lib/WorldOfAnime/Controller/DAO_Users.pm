package WorldOfAnime::Controller::DAO_Users;

use strict;
use parent 'Catalyst::Controller';
use Scalar::Util;
use DateTime;
use JSON;
use List::MoreUtils qw(uniq);

__PACKAGE__->config->{namespace} = '';


# Fetch a user by username (uncached)
sub GetUserByUsername :Local {
    my ( $c, $username ) = @_;
    my $User;

    unless ($User) {

	# We have to search using BINARY to handle people who put weird stuff in their username
	my $Users = $c->model('DB::Users')->search_literal("BINARY username = BINARY '$username'");
	
	while (my $u = $Users->next) {
	    $User = $u;
	}

    }
    
    return $User;
}


# Fetch a user by id (uncached)
sub GetUserByID :Local {
    my ( $c, $id ) = @_;
    my $User;

    unless ($User) {

        $User = $c->model('DB::Users')->find({
	    id => $id,
        });

    }
    
    return $User;
}



# Fetch a cacheable user by id (cache by hashref)
sub GetCacheableUserByID :Local {
    my ( $c, $id ) = @_;
    my %user;
    my $user_ref;
    
    my $cid = "worldofanime:user:$id";
    $user_ref = $c->cache->get($cid);
    
    unless ($user_ref) {
	my $User = $c->model('DB::Users')->find( {
	    id => $id,
	});
	
	if (defined($User)) {

	    $user{'id'}               = $User->id;	    
	    $user{'username'}         = $User->username;
	    $user{'email'}            = $User->email;
	    eval {  $user{'profile_image_id'} = $User->user_profiles->profile_image_id;
		    $user{'background_profile_image_id'} = $User->user_profiles->background_profile_image_id;
		    $user{'filedir'}          = $User->user_profiles->user_profile_image_id->filedir;
		    $user{'filename'}         = $User->user_profiles->user_profile_image_id->filename;
		    $user{'image_height'}     = $User->user_profiles->user_profile_image_id->height;
		    $user{'image_width'}      = $User->user_profiles->user_profile_image_id->width;
	    };
	    $user{'joindate'}         = $User->confirmdate;
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%user, 2592000);
	
	
    } else {
	%user = %$user_ref;
    }    
    
    return \%user;
}


sub GetProfileImageIDs :Local {
    my ( $c, @profile_ids ) = @_;
    my @image_ids;
    
    foreach my $id (@profile_ids) {
	my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $id );
	push (@image_ids, $u->{'profile_image_id'}, $u->{'background_profile_image_id'});	
    }
    
    return @image_ids;
}


# Fetch a cacheable user by username
sub GetCacheableUserByUsername :Local {
    my ( $c, $username ) = @_;
   
    my $redis = $c->model('Redis');

    my $key = "worldofanime:user_by_name:$username";
    $key = WorldOfAnime::Controller::Root::CleanKey( $key );
    my %user = $redis->client->hgetall($key);
    
    unless ( ($user{'id'}) &&
	     ($user{'username'}) &&
	     ($user{'status'}) &&
	     ($user{'email'}) &&
	     ($user{'profile_image_id'}) &&
	     ($user{'background_profile_image_id'}) &&
	     ($user{'filedir'}) &&
	     ($user{'filename'}) &&
	     ($user{'image_height'}) &&
	     ($user{'image_width'}) &&
	     ($user{'joindate'})
	   ) {
	my $User = WorldOfAnime::Controller::DAO_Users::GetUserByUsername( $c, $username );
	
	if (defined($User)) {

	    $user{'id'}               = $User->id;
	    $user{'username'}         = $User->username;
	    $user{'status'}           = $User->status;
	    $user{'email'}            = $User->email;	    
	    $user{'profile_image_id'} = $User->user_profiles->profile_image_id;
	    $user{'background_profile_image_id'} = $User->user_profiles->background_profile_image_id || 0;
	    
	    # Check to make sure their profile image_id is good
	    
	    my $ProfileImage = $c->model('DB::Images')->find( $User->user_profiles->profile_image_id );
	    if (!defined($ProfileImage)) {
		$user{'profile_image_id'} = 14;  # Hard coded default image - change this!
	    }
    
	    my $i = $c->model('Images::Image');
	    $i->build($c, $user{'profile_image_id'});	
	    
	    $user{'filedir'}          = $i->filedir;
	    $user{'filename'}         = $i->filename;
	    $user{'image_height'}     = $i->height;
	    $user{'image_width'}      = $i->width;
	    
	    $user{'joindate'}         = $User->confirmdate;

	    $redis->client->hmset($key, %user);
	}

    }
    
    return \%user;
}


# Fetch a cacheable profile by id (cache by hashref)
sub GetCacheableProfileByID :Local {
    my ( $c, $id ) = @_;
    my %profile;
    my $profile_ref;
    
    my $cid = "worldofanime:profile:$id";
    $profile_ref = $c->cache->get($cid);
    
    unless ($profile_ref) {
	my $User = $c->model('DB::UserProfile')->find( {
	    user_id => $id,
	});
	
	if (defined($User)) {

	    $profile{'name'}                = $User->name;
	    $profile{'birthday'}            = $User->birthday;
	    $profile{'about_me'}            = $User->about_me;
	    $profile{'gender'}              = $User->gender;
	    $profile{'now_watching'}        = $User->now_watching;
	    $profile{'now_playing'}         = $User->now_playing;
	    $profile{'now_reading'}         = $User->now_reading;
	    $profile{'now_doing'}           = $User->now_doing;
	    $profile{'show_visible'}        = $User->show_visible;
	    $profile{'show_age'}            = $User->show_age;
	    $profile{'show_gallery_to_all'} = $User->show_gallery_to_all;
	    $profile{'show_actions'}        = $User->show_actions;
	    
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%profile, 2592000);
	
	
    } else {
	%profile = %$profile_ref;
    }    
    
    return \%profile;
}


# Fetch cacheable email notification preferences (cache by hashref)
sub GetCacheableEmailNotificationPrefsByID :Local {
    my ( $c, $id ) = @_;
    my %prefs;
    my $prefs_ref;
    
    my $cid = "worldofanime:email_notification_prefs:$id";
    $prefs_ref = $c->cache->get($cid);
    
    unless ($prefs_ref) {
	my $User = $c->model('DB::UserProfile')->find( {
	    user_id => $id,
	});
	
	if (defined($User)) {

	    $prefs{'announcements'}              = $User->notify_announcements;
	    $prefs{'friend_request'}             = $User->notify_friend_request;
	    $prefs{'friend_now_box'}             = $User->notify_friend_now_box;
	    $prefs{'comment'}                    = $User->notify_comment;
	    $prefs{'group_comment'}              = $User->notify_group_comment;
	    $prefs{'group_image_comment'}        = $User->notify_group_image_comment;
	    $prefs{'group_new_member'}           = $User->notify_group_new_member;
	    $prefs{'group_member_upload_image'}  = $User->notify_group_member_upload_image;
	    $prefs{'image_comment'}              = $User->notify_image_comment;
	    $prefs{'private_message'}            = $User->notify_private_message;
	    $prefs{'blog_comment'}               = $User->notify_blog_comment;
	    $prefs{'friend_blog_post'}           = $User->notify_friend_blog_post;
	    $prefs{'friend_new_review'}          = $User->notify_friend_new_review;
	    $prefs{'friend_upload_image'}        = $User->notify_friend_upload_image;
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%prefs, 2592000);
	
	
    } else {
	%prefs = %$prefs_ref;
    }    
    
    return \%prefs;
}




# Get Profile Comment Replies
sub GetProfileCommentReplies :Local {
    my ( $self, $c, $parent_comment_id, $highlight_comment_id, $after ) = @_;
    my @image_ids;
    my $RepliesHTML;
    my $latest_reply;

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    my $is_self;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    $after = 0 unless ($after > 0);    
    
    my $Replies = $c->model('DB::UserComments')->search_literal("parent_comment_id = $parent_comment_id AND id > $after");

    while (my $reply = $Replies->next) {
	my $comment_id    = $reply->id;
	$latest_reply     = $reply->id;
	my $commenter_id  = $reply->comment_user_id;
	
	my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $commenter_id );
	my $username   = $u->{'username'};

	my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $commenter_id );
        my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
	push (@image_ids, $profile_image_id);	
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;
	
	my $mult    = ($height / 80);

	my $new_height = int( ($height/$mult) / 1.5 );
	my $new_width  = int( ($width/$mult) /1.5);
	
	my $user_comment  = WorldOfAnime::Controller::Root::ResizeComment($reply->comment, 290);
	$user_comment     = $c->model('Formatter')->clean_html($user_comment);
	my $date          = $reply->createdate;
	my $displayDate    = WorldOfAnime::Controller::Root::PrepareDate($date, 1, $tz);

	$user_comment =~ s/\n/<br \/>/g;				    

	my $reply_div = "individual_reply";
	
	if ($highlight_comment_id == $comment_id) {
	    $RepliesHTML .= "<a name=\"anchor\" />\n";
	    $reply_div = "highlighted_reply";
	}
				
	$RepliesHTML .= "<div id=\"$reply_div\" comment_id=\"$comment_id\" class=\"comment_" . $comment_id . "\">\n";
	if ($viewer_id == $reply->user_id) {
	    $RepliesHTML .= "<a href=\"#\" class=\"delete-comment\" id=\"" . $comment_id . "\"><div id=\"delete_button\">delete</div></a>\n";
	}
	
	$RepliesHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" height=\"$new_height\" width=\"$new_width\" class=\"comment_image\"></a>";
	
	$RepliesHTML .= "<span class=\"reply_post\">$user_comment</span>\n";
	$RepliesHTML .= "<br clear=\"all\">\n";
	$RepliesHTML .= "<span class=\"post_byline\" style=\"font-size: 10px;\">Posted by $username on $displayDate</span>\n";
	$RepliesHTML .= "</div>\n";
    }

    @image_ids = uniq(@image_ids);
    return ($latest_reply, $RepliesHTML, @image_ids);
}


# Get Profile Comment Replies
sub GetGroupCommentReplies :Local {
    my ( $self, $c, $parent_comment_id, $GroupID, $highlight_comment_id, $after ) = @_;
    my $latest_reply;
    my $IsAdmin;
    my $IsOwner;
    my $IsMember;

    my $RepliesHTML;

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    my $is_self;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $UserID = $viewer_id;
    
    $after = 0 unless ($after > 0);    

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });

    # Find out this users status
    
    if ($Group) {
	($IsOwner, $IsAdmin, $IsMember) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    }

    my $replies;
    my $replies_json = WorldOfAnime::Controller::DAO_Users::GetGroupCommentReplies_JSON( $c, $parent_comment_id, $after );
    if ($replies_json) { $replies = from_json( $replies_json ); }


    foreach my $r (@{ $replies}) {
	my $comment_id    = $r->{id};
	next unless ($r->{id} > $after);
	$latest_reply     = $r->{id};
	my $commenter_id  = $r->{commenter_id};
	my $date          = $r->{date};
	my $comment       = $r->{comment};

	my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $commenter_id );
	my $username   = $u->{'username'};

	my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $commenter_id );
        my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;
	
	my $mult    = ($height / 80) || 1;

	my $new_height = int( ($height/$mult) / 1.5 );
	my $new_width  = int( ($width/$mult) /1.5);
	
	my $user_comment  = WorldOfAnime::Controller::Root::ResizeComment($comment, 290);
	$user_comment     = $c->model('Formatter')->clean_html($user_comment);
	my $displayDate    = WorldOfAnime::Controller::Root::PrepareDate($date, 1, $tz);

	$user_comment =~ s/\n/<br \/>/g;
	
	my $reply_div = "individual_reply";
	
	if ($highlight_comment_id == $comment_id) {
	    $reply_div = "highlighted_reply";
	}

	$RepliesHTML .= "<div id=\"$reply_div\" class=\"comment_" . $comment_id . "\">\n";
	if ($IsAdmin) {
	    $RepliesHTML .= "<a href=\"#\" class=\"delete-comment\" id=\"" . $comment_id . "\" group_id=\"" . $GroupID . "\" type=\"reply\"><div id=\"delete_button\">delete</div></a>\n";
	}
	$RepliesHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" height=\"$new_height\" width=\"$new_width\" class=\"comment_image\"></a>";				
	$RepliesHTML .= "<span class=\"post\">$user_comment</span>\n";
	$RepliesHTML .= "<br clear=\"all\">\n";
	$RepliesHTML .= "<span class=\"post_byline\" style=\"font-size: 10px;\">Posted by $username on $displayDate</span>\n";
	$RepliesHTML .= "</div>\n";
    }


    return ($latest_reply, $RepliesHTML);
}



sub GetGroupCommentReplies_JSON :Local :Args(1) {
    my ( $c, $parent_comment_id ) = @_;
    my $replies;
    
    my $cid = "worldofanime:group_comment_replies_json:$parent_comment_id";
    $replies = $c->cache->get($cid);

    unless ($replies) {

	my $Replies = $c->model('DB::GroupCommentReplies')->search_literal("parent_comment_id = $parent_comment_id");

	while (my $reply = $Replies->next) {
	    my $comment_id    = $reply->id;
	    my $commenter_id  = $reply->comment_user_id;
	    my $date          = $reply->createdate;
	    my $comment       = $reply->comment;
	    $comment          = $c->model('Formatter')->clean_html($comment);
	
	    push (@{ $replies} , { 'id' => "$comment_id", 'commenter_id' => "$commenter_id", 'date' => "$date", 'comment' => "$comment" });
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, $replies, 2592000);

    }
    
    if ($replies) { return to_json($replies); }
}



sub OnlineUsersRecord :Local {
    my ( $c, $now_count ) = @_;
    my $high_count;
    my $date;
    
    my $cid_num  = "woa:most_online_count";
    my $cid_date = "woa:most_online_date";
    $high_count  = $c->cache->get($cid_num);
    $date        = $c->cache->get($cid_date);

    my $stat = "most_online";
    my $Stat;
    unless ($high_count && $date) {
	
	$Stat = $c->model('DB::Stats')->find({ stat => $stat });
	
	eval {
	    if (defined($Stat)) {
		#my $s = $Stat->next;
		
		$high_count = $Stat->value;
		$date       = $Stat->createdate;
	    }
	};

    }
    
    if ($now_count > $high_count) {
	$high_count = $now_count;
	
	$Stat = $c->model('DB::Stats')->find({ stat => $stat });

	eval {
	    $Stat->update( {
		value => $now_count,
		createdate => undef,
	    });
	};
	
	$date = $Stat->createdate;
	
	$c->cache->set($cid_num, $high_count, 2592000);
	$c->cache->set($cid_date, $date, 2592000);
    }
    
    return ($high_count, $date);
}





sub AddActionPoints :Local {
    my ($c, $User, $ActionDescription, $ActionNum, $ActionObject) = @_;
    my $UserID;
    
    # This method can accept either a user_id or a user record for User
    # We ultimately need both a UserID and a User record
    # If we receive a user_id, we set UserID to that number, and fetch the user record as User
    # If we receive a user record already, we just need to set UserID to the user_id using $User->id
    
    if (Scalar::Util::looks_like_number($User)) {
	$UserID = $User;
	$User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, $UserID);
    } else {
	$UserID = $User->id;
    }

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $UserID,
	action_id => $ActionNum,
	action_object => $ActionObject,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    ### End User Action    
}


sub CheckForUser :Local {
    my ( $c, $message ) = @_;

    unless ($c->user_exists() ) {
        $c->stash->{error_message} = $message;
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }    
}



sub IsBlock :Local {
    my ( $c, $user_id, $blocked_user_to_check ) = @_;
    
    # This method will determine if user $user_id has blocked user $blocked_user from their profile
    # return either 1 (blocked), or 0 (not blocked)
    
    my $blocked = 0;  # Assume not blocked

    # Look at $user_id's block list
    my $block_list;
    
    my $cid = "woa:user_blocks:$user_id";
    $block_list = $c->cache->get($cid);

    unless ($block_list) {

	my $Blocks = $c->model("DB::UserBlocks")->search({ user_id => $user_id,	});
        
	if (defined($Blocks)) {
	    while (my $b = $Blocks->next) {
		my $blocked_user_id    = $b->has_blocked;
	
		push (@{ $block_list} , { 'id' => "$blocked_user_id" });
	    }
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, $block_list, 2592000);
    }
    
    
    # Now that we're sure we have the list of blocked users, go through them and check to see if the one we are looking for is there
    
    if ($block_list) {
        foreach my $b (@{ $block_list}) {
	
            if ($b->{id} == $blocked_user_to_check) {
		return 1;  # Return immediately if they are being blocked
	    }
	
	}
    }
    
    return $blocked;    
}


sub IsModerator :Local {
    my ( $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_moderator / ) ) {
	$c->stash->{error_message} = "You must be a moderator to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }
}


# Perform user cache cleanup
sub UserCleanup :Local {
    my ( $c, $id, $username ) = @_;

    $c->cache->remove("worldofanime:profile:$id:favorite_anime");
    $c->cache->remove("worldofanime:profile:$id:favorite_movies");
    $c->cache->remove("worldofanime:user:$id");
    $c->cache->remove("worldofanime:profile:$id");
    $c->cache->remove("woa:user_blocks:$id");
    $c->cache->remove("woa:user_profile_image:$id");
    
    # Redis cached items
    my $redis = $c->model('Redis');
    
    my $key = "worldofanime:user_by_name:$username";
    $key = WorldOfAnime::Controller::Root::CleanKey( $key );
    $redis->client->del( $key );
    $redis->client->del("woa/members/profile_image/thumb/$id");
    $redis->client->del("woa/members/profile_image/small/$id");
    $redis->client->del("woa/members/profile_image/full/$id");
}



1;