package WorldOfAnime::Controller::Profile;

use strict;
use warnings;
use Time::Duration;
use Date::Calc qw( check_date Decode_Date_US Today leap_year Delta_Days );
use parent 'Catalyst::Controller';
use JSON;
use List::MoreUtils qw(uniq);


### Stuff for yourself ###

sub view_profile_self :Path('/profile') {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your profile.");

    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $User = $c->model("DB::Users")->find({
        id => $UserID
    });

    my $p = $c->model('Users::UserProfile');
    $p->build( $c, $UserID );
    
    #my ($birth_year, $birth_month, $birth_day) = split(/\-/, $Profile->birthday);
    my $birthday = $p->birthday;
    $birthday =~ s/(T.*$)//; # To get rid of the time on the Date field

    # Get Favorite Anime
    
    my $FavoriteAnime = $c->model("DB::UserFavoriteAnime")->search({
        user_id => $UserID,
    });
    
    
    # Get Favorite Movies
    
    my $FavoriteMovies = $c->model("DB::UserFavoriteMovies")->search({
    	user_id => $UserID,
    });
    
    
    # Get Blocked Users
    
    my $BlockedUsers = $c->model("DB::UserBlocks")->search({
	user_id => $UserID,
    });
    

    # Get possible timezones
    
    my $Timezones = $c->model("DB::Timezones")->search({
    },{
	order_by => 'timezone ASC',
    });
    
    $p->signature( WorldOfAnime::Controller::Root::ResizeComment($p->signature, 480) );
    
    $c->stash->{username}        = $User->username;
    $c->stash->{Profile}         = $p;
    $c->stash->{timezones}       = $Timezones;
    $c->stash->{favorite_anime}  = $FavoriteAnime;    
    $c->stash->{favorite_movies} = $FavoriteMovies;
    $c->stash->{blocked_users}   = $BlockedUsers;
    $c->stash->{birthday}        = $birthday;
    $c->stash->{template}        = 'profile/profile_self.tt2';
}


sub view_profile_self_notifications :Path('/edit_notifications') {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit your profile.");

    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $User = $c->model("DB::Users")->find({
        id => $UserID
    });
    
    my $Profile = $c->model("DB::UserProfile")->find({
        user_id => $UserID
    });
    
    my $IsSuppressed = WorldOfAnime::Controller::DAO_Email::IsSuppressed($c, $User->email);

    my $NotificationPrefs = WorldOfAnime::Controller::Notifications::PopulateNotificationPrefs($c);

    $c->stash->{username} = $User->username;
    $c->stash->{IsSuppressed} = $IsSuppressed;
    $c->stash->{Profile}  = $Profile;
    $c->stash->{Prefs}    = $NotificationPrefs;
    $c->stash->{template} = 'profile/profile_self_notifications.tt2';
}


sub view_profile_self_appearance :Path('/edit_appearance') {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit your profile.");

    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $User = $c->model("DB::Users")->find({
        id => $UserID
    });
    
    my $p = $c->model('Users::UserProfileAppearance');
    $p->build( $c, $UserID );
    

    $c->stash->{Profile}  = $p;
    $c->stash->{template} = 'profile/profile_self_appearance.tt2';    
}


sub update_profile_appearance :Path('/update_profile_appearance') {
    my ( $self, $c ) = @_;
    my $DesiredWidth;
    my $ThumbImage;
    my $ThumbWidth;
    my $ThumbHeight;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to update your profile.");

    $c->detach('view_profile_self_appearance') unless ($c->req->params->{'do_update'});
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $User = $c->model("DB::Users")->find({
        id => $UserID
    });
    
    my $p = $c->model('Users::UserProfileAppearance');
    $p->build( $c, $UserID );
    

    my $background_image_id;

    # Handle background image
    if ($c->req->params->{background_image}) {
        my $upload   = $c->req->upload('background_image');
	#my $filedir  = 'backgrounds/profile';
        my $filename = $upload->filename;
	
	$background_image_id = WorldOfAnime::Controller::DAO_Images::upload_image_s3( $c, $upload, $filename);

    } else {
        # An image wasn't entered.  We need to get the image_profile_id so we don't blank it out
        my $Profile = $c->model("DB::UserProfile")->find({
            user_id => $UserID,
        });
        
        $background_image_id = $Profile->background_profile_image_id;        
    }
    
    
    # If they want their background image gone, do it!
    
    if ($c->req->params->{'remove_background_image'}) {
    	undef $background_image_id;
    }
    
    $p->background_image_id( $background_image_id );
    $p->update( $c );
    $p->save( $c );

    # Show them a "Profile Updated Page"
    $c->stash->{'notice_header'} = "Your profile has been updated.";
    $c->detach('view_profile_self_appearance');
}


sub update_profile :Path('/update_profile') {
    my ( $self, $c ) = @_;
    my $DesiredWidth;
    my $ThumbImage;
    my $ThumbWidth;
    my $ThumbHeight;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to update your profile.");

    $c->detach('view_profile_self') unless ($c->req->params->{'do_update'});

    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $User = $c->model("DB::Users")->find({
        id => $UserID
    });
    
    my $p = $c->model('Users::UserProfile');
    $p->build( $c, $UserID );

    my $show_age     = ($c->req->params->{'show_age'}) ? 1 : 0;
    
    if ( !($c->req->params->{'birthday'}) && ($show_age) ) {
        $c->stash->{error_message} = "If you select Show Age, you must provide your birthday.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();			
    }

    $p->validate_birthday( $c );
    
    if (!($p->is_valid_birthday)) {
        $c->stash->{error_message} = $p->error_message;
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }

    my $profile_image_id;
    my $old_profile_image_id = $p->profile_image_id;
    
    # Handle image profile
    if ($c->req->params->{profile_image}) {
	my $upload   = $c->req->upload('profile_image');
        my $filename = $upload->filename;
        
        $profile_image_id = WorldOfAnime::Controller::DAO_Images::upload_image_s3( $c, $upload, $filename);

	# TODO
	# If their old_profile_image_id is not used anywhere else, we can safely delete it
	if (!(WorldOfAnime::Controller::DAO_Images::IsImageUsed( $c, $old_profile_image_id ))) {
	    
	}
	
    } else {
        # An image wasn't entered.  Keep their profile_image_id as it used to be
        
        $profile_image_id = $old_profile_image_id;        
    }


    $p->profile_image_id( $profile_image_id );
    $p->update( $c );
    $p->save( $c );


    # Handle "Favorite Anime" chunk

    # Create a better way to handle this later
    
    # First, empty this users UserFavoriteAnime table
        
    my $Faves = $c->model("DB::UserFavoriteAnime")->search({
        user_id => $UserID,
    });
        
    $Faves->delete;        
        
    my @favorite_animes = split(/\n/, $c->req->params->{favorite_anime});
        
    foreach my $anime (@favorite_animes) {
        $anime =~ s/\n//g;
        $anime =~ s/\r//g;
        $anime =~ s/^\s*//;
        $anime =~ s/\s*$//;
            
            my $AnimeTitle = $c->model("DB::AnimeTitles")->update_or_create({
            name        => $anime,
            modify_date => undef,
            create_date => undef,
            },{ key => 'anime_title' });
            
        my $anime_id = $AnimeTitle->id;
            
        $c->model("DB::UserFavoriteAnime")->create({
            user_id        => $UserID,
            anime_title_id => $anime_id,
            modify_date    => undef,
            create_date    => undef,
        });
    }



    # Handle "Favorite Movies" chunk

    # Create a better way to handle this later
    
    # First, empty this users UserFavoriteMovies table
        
    my $MovieFaves = $c->model("DB::UserFavoriteMovies")->search({
        user_id => $UserID,
    });
        
    $MovieFaves->delete;        
        
    my @favorite_movies = split(/\n/, $c->req->params->{favorite_movies});
        
    foreach my $movie (@favorite_movies) {
        $movie =~ s/\n//g;
        $movie =~ s/\r//g;
        $movie =~ s/^\s*//;
        $movie =~ s/\s*$//;
            
            my $MovieTitle = $c->model("DB::MovieTitles")->update_or_create({
            name        => $movie,
            modify_date => undef,
            create_date => undef,
            },{ key => 'movie_title' });
            
        my $movie_id = $MovieTitle->id;
            
        $c->model("DB::UserFavoriteMovies")->create({
            user_id        => $UserID,
            movie_title_id => $movie_id,
            modify_date    => undef,
            create_date    => undef,
        });
    }
    
    
    
    # Handle "Blocked Users" chunk

    # Create a better way to handle this later
    
    # First, empty this users UserFavoriteMovies table
        
    my $UserBlocks = $c->model("DB::UserBlocks")->search({
        user_id => $UserID,
    });
        
    $UserBlocks->delete;
    
    my @blocked_users = split(/\n/, $c->req->params->{blocked_users});
    
    foreach my $bu (@blocked_users) {
	
	$bu =~ s/^\s+//;
	$bu =~ s/\s+$//;
	
	# Figure out ID from username
	
	my $BU = $c->model("DB::Users")->find({
	    username => $bu,
	});
	
	if ($BU) {
	    
	    $c->model("DB::UserBlocks")->create({
		user_id     => $UserID,
		has_blocked => $BU->id,
		modify_date => undef,
		create_date => undef,
	    });
	}
    }
    


    # Now that we are done, empty their cache so the new information will be fetched next time
    
    WorldOfAnime::Controller::DAO_Users::UserCleanup( $c, $UserID, $User->username);

    # Set their timezone cookie, in case it has changed
    
    $c->response->cookies->{timezone} = { value => $c->req->params->{'timezone'} };
    
    # Show them a "Profile Updated Page"
    $c->stash->{'notice_header'} = "Your settings have been saved.";
    $c->detach('view_profile_self');
}





sub update_profile_notifications :Path('/update_profile_notifications') {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to update your profile.");

    unless ($c->req->params->{'do_update'}) {
	$c->detach('view_profile_self');
    }

    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $User = $c->model("DB::Users")->find({
        id => $UserID
    });
    
    if ($c->req->params->{'suppress_email'}) {
	WorldOfAnime::Controller::DAO_Email::SuppressUser($c, $User->email);
    } else {
	WorldOfAnime::Controller::DAO_Email::UnSuppressUser($c, $User->email);
    }

    my $notify_announcements = 0;
    my $notify_friend_request = 0;
    my $notify_comment = 0;
    my $notify_image_comment = 0;
    my $notify_private_message = 0;
    my $notify_blog_comment = 0;
    my $notify_friend_now_box = 0;
    my $notify_friend_blog_post = 0;
    my $notify_friend_upload_image = 0;
    my $notify_friend_new_review = 0;

    my $notify_group_comment = 0;
    my $notify_group_image_comment = 0;
    my $notify_group_new_member = 0;
    my $notify_group_member_upload_image = 0;    
    
    if ($c->req->params->{'notify_announcements'}) {
    	$notify_announcements = 1;
    }

    if ($c->req->params->{'notify_friend_request'}) {
    	$notify_friend_request = 1;
    }
    
    if ($c->req->params->{'notify_comment'}) {
    	$notify_comment = 1;
    }
    
    if ($c->req->params->{'notify_image_comment'}) {
    	$notify_image_comment = 1;
    }    
    
    if ($c->req->params->{'notify_private_message'}) {
    	$notify_private_message = 1;
    }            

    if ($c->req->params->{'notify_blog_comment'}) {
    	$notify_blog_comment = 1;
    }

    if ($c->req->params->{'notify_friend_now_box'}) {
    	$notify_friend_now_box = 1;
    }
    
    if ($c->req->params->{'notify_friend_blog_post'}) {
    	$notify_friend_blog_post = 1;
    }    

    if ($c->req->params->{'notify_friend_upload_image'}) {
    	$notify_friend_upload_image = 1;
    }
    
    if ($c->req->params->{'notify_friend_new_review'}) {
	$notify_friend_new_review = 1;
    }
    
    
    

    if ($c->req->params->{'notify_group_comment'}) {
    	$notify_group_comment = 1;
    }
    
    if ($c->req->params->{'notify_group_image_comment'}) {
    	$notify_group_image_comment = 1;
    }
    
    if ($c->req->params->{'notify_group_new_member'}) {
    	$notify_group_new_member = 1;
    }
    
    if ($c->req->params->{'notify_group_member_upload_image'}) {
    	$notify_group_member_upload_image = 1;
    }
    
	    $c->model("DB::UserProfile")->update_or_create({
	    user_id  => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
	    notify_announcements   => $notify_announcements,
	    notify_friend_request  => $notify_friend_request,
	    notify_comment         => $notify_comment,
	    notify_image_comment   => $notify_image_comment,
	    notify_private_message => $notify_private_message,
	    notify_blog_comment    => $notify_blog_comment,
	    notify_friend_now_box  => $notify_friend_now_box,
	    notify_friend_blog_post => $notify_friend_blog_post,
	    notify_friend_upload_image => $notify_friend_upload_image,
	    notify_friend_new_review   => $notify_friend_new_review,
	    notify_group_comment   => $notify_group_comment,
	    notify_group_image_comment => $notify_group_image_comment,
	    notify_group_new_member => $notify_group_new_member,
	    notify_group_member_upload_image => $notify_group_member_upload_image,

    },{ key => 'user_id' });

    # Now handle Site Notifications
    
    # First, remove all from cache
    
    WorldOfAnime::Controller::Notifications::SiteNotificationsClearCache( $c );
    
    # Now, set new ones
    
    my @NotificationList = WorldOfAnime::Controller::Notifications::AllSiteNotifications($c);
    
    foreach my $notification (@NotificationList) {
	
	my $pref = 0;

	if ($c->req->params->{$notification}) {
	    $pref = 1;
	}
    
	$c->model('DB::UserProfileSiteNotifications')->update_or_create({
		    user_id => $UserID,
		    notification => $notification,
		    receive => $pref,
	},{ key => 'user_notification' });
    }
    
    # Remove notification_prefs cache
    $c->cache->remove("worldofanime:email_notification_prefs:$UserID");
    
    # Now, fetch an unused new set of prefs (to force a recaching)
    my $z = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $UserID );

    # Show them a "Profile Updated Page"
    $c->stash->{'notice_header'} = "Your settings have been saved.";
    $c->detach('view_profile_self_notifications');
}




sub friend_requests :Path('/friend_requests') {
    my ( $self, $c ) = @_;
    my $message = "You currently have no friend requests";
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your friend requests.");
    
    my $UserFriendsHTML;

    my $FriendRequests = $c->model("DB::UserFriends")->search({
        user_id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
        status  => 1,
	friend_user_id => { '>', '0' }
    });

    if ($FriendRequests->count) {
	$message = "The following people have requested to be your friend";
	while (my $friend = $FriendRequests->next) {
				my $username = $friend->friends->username;
				
				my $p = $c->model('Users::UserProfile');
				$p->get_profile_image( $c, $friend->friends->id );

				my $profile_image_id = $p->profile_image_id;
				
				my $i = $c->model('Images::Image');
				$i->build($c, $profile_image_id);
				my $profile_image_url = $i->thumb_url;

				my $join_date   = $friend->friends->confirmdate;
				my $friend_date   = $friend->modifydate;
				my $displayJoinDate      = WorldOfAnime::Controller::Root::PrepareDate($join_date, 1, $tz);
				my $displayFriendDate    = WorldOfAnime::Controller::Root::PrepareDate($friend_date, 1, $tz);
	
				my $image_gallery_link;
				$image_gallery_link = "<span class=\"top_user_profile_link\"><a href=\"/profile/$username/gallery\">Image Gallery</a></span><br />\n";

				$UserFriendsHTML .= "<div id=\"top_user_profile_box\" class=\"friend_" . $friend->friend_user_id . "\">\n";
				$UserFriendsHTML .= "<table border=\"0\">\n";
				$UserFriendsHTML .= "	<tr>\n";
				$UserFriendsHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
				$UserFriendsHTML .= "			<a href=\"/profile/$username\"><img src=\" $profile_image_url\" border=\"0\"></a>";
				$UserFriendsHTML .= "		</td>\n";
				$UserFriendsHTML .= "		<td valign=\"top\" width=\"380\">\n";
				$UserFriendsHTML .= "			<span class=\"top_user_profile_name\"><a href=\"/profile/$username\">$username</a></span><br />\n";
				$UserFriendsHTML .= "		</td>\n";
				$UserFriendsHTML .= "		<td valign=\"top\">\n";
				$UserFriendsHTML .= "			<span class=\"top_user_profile_link\"><a href=\"/profile/$username\">Profile</a></span><br />\n";
			        $UserFriendsHTML .= "			$image_gallery_link";
				$UserFriendsHTML .= "			<span class=\"top_user_profile_link\"><a href=\"/blogs/$username\">Blog</a></span><br />\n";
				$UserFriendsHTML .= "		</td>\n";
				$UserFriendsHTML .= "	</tr>\n";
				$UserFriendsHTML .= "	<tr>\n";
				$UserFriendsHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Joined $displayJoinDate</span><br />\n";
				$UserFriendsHTML .= "                                               <span class=\"top_user_profile_date\">Requested Friendship on $displayFriendDate</span>\n";				
				$UserFriendsHTML .= "<span style=\"float: right\"><a href=\"#\" class=\"friend-accept\" id=\"" . $friend->friend_user_id . "\"><font color=\"green\">accept</font></a> ";
				$UserFriendsHTML .= "<a href=\"#\" class=\"friend-reject\" id=\"" . $friend->friend_user_id . "\"><font color=\"red\">reject</font></a></span></td>\n";
				$UserFriendsHTML .= "	</tr>\n";
				$UserFriendsHTML .= "</table>\n";
				$UserFriendsHTML .= "</div>\n\n";
				$UserFriendsHTML .= "<p />\n";
	}
    }

    $c->stash->{message} = $message;
    $c->stash->{FriendRequests} = $UserFriendsHTML;
    $c->stash->{template} = 'profile/friend_requests.tt2';
}


sub reject_friend :Path('/profile/friend_request/reject') :Args(0) {
    my ( $self, $c ) = @_;
    my $body;
    my $Email;

    my $id = $c->req->param('friend');
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Try to delete the request of id $id and user_id = $UserID

    my $Request = $c->model("DB::UserFriends")->find({
	friend_user_id => $id,
        user_id        => $UserID,
    });
    
    $Request->delete;
    
    # Do we want to contact anyone?
    
    my $username = $Request->users->username;
    my $friend_name = $Request->friends->username;

    my $HTMLUsername = $friend_name;
    $HTMLUsername =~ s/ /%20/g;
    
    my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $id );
    
    if ($e->{friend_request}) {
    
	$body = <<EndOfBody;
I'm sorry to say that $username has rejected your friend request.

To see your profile, go to http://www.worldofanime.com/profile/$HTMLUsername
EndOfBody
    
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $Request->friends->email, 1, $body, "$username has rejected your friend request.");

    }

	### Create Notification
 
	WorldOfAnime::Controller::Notifications::AddNotification($c, $id, "{p:$username} has rejected your friend request.", 11);
	
	# Update Friend Status
	WorldOfAnime::Controller::DAO_Friends::FriendStatusChange( $c, $UserID, $id);
	
	# Remove their num_friend_requests cache key
	$c->cache->remove("worldofanime:num_friend_requests:$UserID");    	
}


sub accept_friend :Path('/profile/friend_request/accept') :Args(0) {
    my ( $self, $c ) = @_;
    my $body;
    my $Email;

    my $id = $c->req->param('friend');
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # First accept the request of id $id and user_id = $UserID

    my $Request = $c->model("DB::UserFriends")->find({
        user_id        => $UserID,
	friend_user_id => $id,
    });
    
    $Request->update({ status => 2 });
    
    # Now, add a new friendship between $user_id and $id

    my $RecipRequest = $c->model("DB::UserFriends")->create({
        user_id         => $id,
        friend_user_id  => $UserID,
        status          => 2,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    
    # Do we want to contact anyone?
    
    my $username = $Request->users->username;
    my $friend_name = $Request->friends->username;

    my $HTMLUsername = $friend_name;
    $HTMLUsername =~ s/ /%20/g;
    
    my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $id );
    
    if ($e->{friend_request}) {
    
	$body = <<EndOfBody;
Great news!  $username has accepted your friend request!

To see your profile, go to http://www.worldofanime.com/profile/$HTMLUsername
EndOfBody
    
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $Request->friends->email, 1, $body, "$username is now your friend.");

    }
    

    ### Create User Action
    
    my $ActionDescription = "{p:" . $Request->users->username . "} and ";
    $ActionDescription   .= "{p:" . $Request->friends->username . "} are now friends";
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Request->users->id,
	action_id => 10,
	action_object => $Request->friends->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    ### End User Action

    
    ### Create User Action
    
    $ActionDescription  = "{p:" . $Request->friends->username . "} and ";
    $ActionDescription .= "{p:" . $Request->users->username . "} are now friends";

    $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Request->friends->id,
	action_id => 10,
	action_object => $Request->users->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    ### End User Action
    
    
    ### Create Notification
 
    WorldOfAnime::Controller::Notifications::AddNotification($c, $id, "{p:$username} has accepted your friend request.", 10);
    
    WorldOfAnime::Controller::DAO_Friends::FriendCleanupChange( $c, $UserID );
    WorldOfAnime::Controller::DAO_Friends::FriendCleanupChange( $c, $id );
    
    # Now, calculate new friends (pre-populate memcached object)
    WorldOfAnime::Controller::DAO_Friends::CalcFriends( $c, $UserID );
    WorldOfAnime::Controller::DAO_Friends::CalcFriends( $c, $id );
    
    # Update Friend Status
    WorldOfAnime::Controller::DAO_Friends::FriendStatusChange( $c, $UserID, $id);
}


### Remove a friend

sub remove_friend :Path('/profile/friend/remove') :Args(0) {
    my ( $self, $c ) = @_;
    my $ActionDescription;
    my $Action;
    my $UserAction;
    my $body;
    my $Email;
    
    my $friend_id = $c->req->param('friend');
    my $UserID    = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Remove friendships
    
    my $Friend = $c->model('DB::UserFriends')->find({
	user_id => $UserID,
	friend_user_id => $friend_id,
    });
    
    my $RecipFriend = $c->model('DB::UserFriends')->find({
	user_id => $friend_id,
	friend_user_id => $UserID,
    });
    
    
    # Record actions and points


    ### Create User Action
    
    $ActionDescription  = "{p:" . $Friend->friends->username . "} and ";
    $ActionDescription .= "{p:" . $Friend->users->username . "} are no longer friends.  Sorry it didn't work out.";
    
    $Action = $c->model("DB::Actions")->find({ id => 11});
    
    $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Friend->friends->id,
	action_id => 11,
	action_object => $Friend->friends->id,
	description => $ActionDescription,
	points => 0,
	modify_date => undef,
	create_date => undef,
    });
    
    ### End User Action  


    ### Create User Action
    
    $ActionDescription  = "{p:" . $Friend->users->username . "} and ";
    $ActionDescription .= "{p:" . $Friend->friends->username . "} are no longer friends.  Sorry it didn't work out.";
    
    $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Friend->users->id,
	action_id => 11,
	action_object => $Friend->users->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    ### End User Action
    
    
    # Send e-mail to unfriended person
    
    my $username = $Friend->users->username;
    my $friend_name = $Friend->friends->username;
    
    my $HTMLUsername = $friend_name;
    $HTMLUsername =~ s/ /%20/g;
    
    
    my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $Friend->friends->id );
    
    if ($e->{friend_request}) {    

	$body = <<EndOfBody;
Bad news.  $username has removed you as a friend on World of Anime.

To see your profile, go to http://www.worldofanime.com/profile/$HTMLUsername
EndOfBody

	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $Friend->friends->email, 1, $body, "$username has removed you as a friend.");

    }
    
    $Friend->delete;
    $RecipFriend->delete;
    
    ### Create Notification
 
    #WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "You have removed <a href=\"/profile/$friend_name\">$friend_name</a> as a friend.", 6);		    
    WorldOfAnime::Controller::Notifications::AddNotification($c, $friend_id, "{p:$username} has removed you as a friend.", 6);		    
    
    WorldOfAnime::Controller::DAO_Friends::FriendCleanupChange( $c, $UserID );
    WorldOfAnime::Controller::DAO_Friends::FriendCleanupChange( $c, $friend_id );
    
    # Now, calculate new friends (pre-populate memcached object)
    WorldOfAnime::Controller::DAO_Friends::CalcFriends( $c, $UserID );
    WorldOfAnime::Controller::DAO_Friends::CalcFriends( $c, $friend_id );
    
    # Update Friend Status
    WorldOfAnime::Controller::DAO_Friends::FriendStatusChange( $c, $UserID, $friend_id);    
}



### Delete a comment

sub delete_comment :Path('/profile/comment/delete') :Args(0) {
    my ( $self, $c ) = @_;

    my $id = $c->req->param('comment');
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Try to delete the comment of id $id and user_id = $UserID

    my $Comment = $c->model("DB::UserComments")->search({
	id             => $id,
        user_id        => $UserID,
    });
    
    $Comment->delete;
    
    # Remove from cache
    
    # Clear this comment (and its parent) from memcached
    
    my $NewComment = $c->model('Comments::ProfileComment');
    $NewComment->build( $c, $id );
    $NewComment->clear( $c );    
}


###### Now Box



### Ajax Updates

sub ajax_update_now_action :Local {
    my ( $self, $c ) = @_;
    my $body;
    my $Email;
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my %ActionTextMap = ('now_watching' => 'watching',
		      'now_playing'  => 'playing',
		      'now_reading'  => 'reading',
		      'now_doing'    => 'doing');
    
    my %ActionPointMap = ('now_watching' => 15,
		      'now_playing'  => 16,
		      'now_reading'  => 17,
		      'now_doing'    => 18);
    

    my $type   = $c->req->params->{'type'};
    my $action = $c->req->params->{'action'};
    
    my $ActionText   = $ActionTextMap{$type};
    my $ActionPoints = $ActionPointMap{$type};
    
    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, $user_id);
    my $Username = $User->username;

    my $ToUpdate = $c->model('DB::UserProfile')->find({
       user_id => $User->id,
      });
    
    $ToUpdate->update( { $type => $action });
    
    # Set Action  (... is now {action})
    
    my $ActionDescription  = "{p:" . $Username . "} is now $ActionText " . $action;

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $User->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
   if ($action) {
    
	# Email friends
    
	my $to_email;
	my $from_email = '<meeko@worldofanime.com> World of Anime';
	my $subject = "$Username has updated what they are $ActionText.";

	$body = <<EndOfBody;
Your friend $Username is now $ActionText $action

To stop receiving these updates, log on to your profile at http://www.worldofanime.com/ and change your preference by unchecking "When a friend updates what they are doing" under Notifications.
EndOfBody
    
	my $friends;
	my $friends_json = WorldOfAnime::Controller::DAO_Friends::GetFriends_JSON( $c, $user_id );
	if ($friends_json) { $friends = from_json( $friends_json ); }

	foreach my $f (@{ $friends}) {
	
	    my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $f->{id} );
    
	    if ($e->{friend_now_box}) {
	        push (@{ $to_email}, { 'email' => $f->{email} });
	    }
	
	    ### Create Notification
 
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $f->{id}, "{p:$Username} is now $ActionText $action.", $ActionPoints);		
        }
    
        if ($to_email) {
    	WorldOfAnime::Controller::DAO_Email::StageEmail($c, $from_email, $subject, $body, to_json($to_email));	    
        }      
    
    } # if $text
    
    # Remove profile cache
    $c->cache->remove("worldofanime:profile:$user_id");
    
    $c->response->body("updated");

}




sub view_individual_comment :Local {
    my ( $self, $c, $user, $action1, $fetch_comment_id ) = @_;
    my @image_ids;
    my $raw_comment_html;
    my $latest_reply = 0;
    my $autoScroll = 1;
    my ($metadescription, $metadate, $metadisplaydate);
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Try to get a user profile

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID         = $u->{'id'};
    push (@image_ids, $u->{'profile_image_id'}, $u->{'background_profile_image_id'});

    my $is_self = ( ($viewer_id) && ($viewer_id == $UserID) ) ? 1 : 0;

    # Have you blocked this user?
    my $IsBlock = WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $UserID, $viewer_id );
    if ($IsBlock) { $c->stash->{is_blocked} = 1; }

    my $Comment = $c->model('Comments::ProfileComment');
    $Comment->build( $c, $fetch_comment_id );

    # If this comment_id has a parent_comment_id, we want to fetch that instead
    my $parent_comment_id;
    my $comment_owner;
    
    if ($Comment->id) {
	   $parent_comment_id = $Comment->parent_comment_id;

	   # Use this to build a unique title and description
	   $metadescription   = $Comment->comment;
	   $metadescription  =~ s/\"//g;
	   $metadate          = $Comment->createdate;
	   $metadisplaydate   = WorldOfAnime::Controller::Root::PrepareDate($metadate, 1, $tz);
    }

    if ($parent_comment_id) {
	   $Comment->build( $c, $parent_comment_id );
    }

    if ($Comment->id) {
	   $Comment->build_replies( $c );
	   $comment_owner    = $Comment->user_id;
	   $raw_comment_html = $Comment->raw_comment_html;
	   my @profile_ids = $Comment->profile_ids($c);
	   my @profile_image_ids = WorldOfAnime::Controller::DAO_Users::GetProfileImageIDs( $c, @profile_ids );
	   push (@image_ids, @profile_image_ids);
    }
    
    @image_ids = uniq(@image_ids);
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids ) &&
                          WorldOfAnime::Controller::DAO_Images::IsExternalLinksApprovedPreRender( $c, $raw_comment_html );
    $c->stash->{is_self}     = $is_self;
    $c->stash->{is_block}    = $IsBlock;
    $c->stash->{comment}     = $Comment;
    $c->stash->{user}        = $u;
    $c->stash->{autoScroll}  = $autoScroll;
    $c->stash->{metadate}    = $metadisplaydate;
    $c->stash->{metadescription}  = $metadescription;
    $c->stash->{fetch_comment_id} = $fetch_comment_id;
    $c->stash->{template}    = 'profile/individual_comment.tt2';    
}


sub view_profile :Path('/profile') :Args(1) {
    my ( $self, $c, $user ) = @_;
    my @image_ids;
    my $is_self;
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $cpage = $c->req->params->{'cpage'} || 1;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Try to get a user profile

    # Get cacheable user
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    push (@image_ids, $u->{'profile_image_id'}, $u->{'background_profile_image_id'});

    my $username   = $u->{'username'};
    my $filedir    = $u->{'filedir'};
    my $filename   = $u->{'filename'};
    my $height     = $u->{'image_height'};
    my $width      = $u->{'image_width'};
    my $join_date  = $u->{'joindate'};
    my $UserID     = $u->{'id'};
    my $status     = $u->{'status'};

    
    # If no user, die with error
    
    unless ( ($UserID) && ($status == 1) ) {
	$c->stash->{error_message} = "Doesn't look like that's a user.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
   
    # Get cacheable profile
    
    my $prof = $c->model('Users::UserProfile');
    $prof->build( $c, $UserID );    
    
    my $p = WorldOfAnime::Controller::DAO_Users::GetCacheableProfileByID( $c, $UserID );
    
    my $birthday  = $prof->birthday;
    my $about_me  = $prof->about_me;
    my $gender    = $prof->gender;

    my $now_watching = $p->{'now_watching'};
    my $now_playing  = $p->{'now_playing'};
    my $now_reading  = $p->{'now_reading'};
    my $now_doing    = $p->{'now_doing'};
    
    $about_me =~ s/\n/<br \/>/g;
    $gender =~ s/^m$/Male/;
    $gender =~ s/^f$/Female/;
    $gender =~ s/^u$//;

    
    # Is Online?
    
    my $cid = "worldofanime:online:$UserID";
    my $is_online = $c->cache->get($cid);
    
    my $displayJoinDate = WorldOfAnime::Controller::Root::PrepareDate($join_date, 1, $tz);
    
    if (($viewer_id) && ($viewer_id == $UserID)) { $is_self = 1; }

    # Number of friends
    my $NumFriends = WorldOfAnime::Controller::DAO_Friends::GetNumFriends( $c, $UserID );


    # Have you blocked this user?
    my $IsBlock = WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $UserID, $viewer_id );
    if ($IsBlock) { $c->stash->{is_blocked} = 1; }    
    

    ##### Get User Comments
    my $UserCommentsHTML;
    my $UserComments;

    $UserCommentsHTML .= "<div class=\"new_comment\"><p> </p></div>\n"; # Create empty div for first reply
    
    my $cpager;
    unless ($UserComments) {
        $UserComments = $c->model("DB::UserComments")->search({
            user_id => $UserID,
	    parent_comment_id => 0,
	},{
	  page      => "$cpage",
	  rows      => 10,
	  order_by  => 'createdate DESC',
	  });
    }

    if (defined($UserComments)) {
	$cpager = $UserComments->pager();

	      while (my $comment = $UserComments->next) {
	    			my $comment_id    = $comment->id;
				my $commenter_id  = $comment->comment_user_id;
				
				my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $commenter_id );
							
				my $p = $c->model('Users::UserProfile');
				$p->get_profile_image( $c, $commenter_id );
				my $profile_image_id = $p->profile_image_id;
				push (@image_ids, $profile_image_id);
				
				my $i = $c->model('Images::Image');
				$i->build($c, $profile_image_id);
				my $profile_image_url = $i->thumb_url;				

				my $username   = $u->{'username'};
				
				my $user_comment  = WorldOfAnime::Controller::Root::ResizeComment($comment->comment, 370);
				$user_comment     = $c->model('Formatter')->clean_html($user_comment);
	    			my $date          = $comment->createdate;
				my $displayDate   = WorldOfAnime::Controller::Root::PrepareDate($date, 1, $tz);
				my $latest_reply  = 0;
				

				$filedir =~ s/u\/$/t80\//;
				
				$user_comment =~ s/\n/<br \/>/g;

				$UserCommentsHTML .= "<div id=\"individual_post\" class=\"comment_" . $comment_id . "\">\n";
				if ($is_self) {
				    $UserCommentsHTML .= "<a href=\"#\" class=\"delete-comment\" id=\"" . $comment_id . "\"><div id=\"delete_button\">delete</div></a>\n";
				}

				$UserCommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" class=\"comment_image\"></a>";				

				$UserCommentsHTML .= "<span class=\"post\">$user_comment</span>\n";
				$UserCommentsHTML .= "<br clear=\"all\">\n";
				$UserCommentsHTML .= "<span class=\"post_byline\">Posted by $username on $displayDate</span>\n";


				my ($latest, $RepliesHTML, @reply_image_ids) = WorldOfAnime::Controller::DAO_Users::GetProfileCommentReplies($self, $c, $comment->id );
				    push (@image_ids, @reply_image_ids);
				    $UserCommentsHTML .= " <p> $RepliesHTML </p>" if ($RepliesHTML);
				    $latest_reply = $latest if ($latest);
				    $UserCommentsHTML .= "<div class=\"replies_" . $comment->id . "\"><p> </p></div>\n"; # Create empty div to pull in replies via Ajax

				if ( ($viewer_id) && !($IsBlock) ) {
				    $UserCommentsHTML .= "<div id=\"setup_reply_" . $comment_id . "\" style=\"text-align: right;\"><a href=\"#\" class=\"reply_linky\" onclick=\"javascript:\$('#reply_" . $comment_id . "').show();\$('#add_comment #comment_box_" . $comment_id . "').focus();\$('#setup_reply_" . $comment_id . "').hide();return false\">Post a Reply</a></div>\n";
				}

				if ( ($viewer_id) && !($IsBlock) ) {
				    $UserCommentsHTML .= "<div id=\"reply_" . $comment_id . "\" class=\"reply_box\">";
				    $UserCommentsHTML .= "<h2>Post a Reply</h2>\n";
				    $UserCommentsHTML .= "<form id=\"add_comment\" parent=\"$comment_id\" user=\"$user\" latest=\"$latest_reply\">";
				    $UserCommentsHTML .= "<input type=\"hidden\" name=\"parent_comment\" value=\"" . $comment_id . "\">\n";
				    $UserCommentsHTML .= "<textarea id=\"comment_box_" . $comment_id . "\" rows=\"4\" cols=\"44\" name=\"comment_box_" . $comment_id . "\"></textarea>\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "<input type=\"submit\" value=\"Reply\" style=\"float: right; margin-right: 25px; margin-top: 5px; margin-bottom: 5px;\" class=\"removable\">\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "</form>\n";
				    $UserCommentsHTML .= "</div>\n";
				}
				
				$UserCommentsHTML .= "<br clear=\"all\">\n";
				$UserCommentsHTML .= "</div>\n";
	    	}
    }

	my $UserFriendsHTML;
	
	
    # Get (your) friendship status
    
	my ($friend_status, $friend_date) = WorldOfAnime::Controller::DAO_Friends::GetFriendStatus( $c, $viewer_id, $UserID, 1);
        

	##### Get Favorite Anime

	my $FavoriteAnimeHTML = $c->cache->get("worldofanime:profile:$UserID:favorite_anime");
    
	unless ($FavoriteAnimeHTML) {
		  my $FavoriteAnime = $c->model("DB::UserFavoriteAnime")->search({
  		     user_id => $UserID,
	    },{
		   	order_by => 'create_date ASC',
	  	});
	  	
		if (defined($FavoriteAnime)) {
        	  	while (my $fa = $FavoriteAnime->next) {
        	  		eval {
				    $FavoriteAnimeHTML .= $fa->favorite_to_anime_title->name;
				    $FavoriteAnimeHTML .= ", ";
				};
		  	}
		}
	  	
	  	$FavoriteAnimeHTML =~ s/\,$//;
	  	
			$c->cache->set("worldofanime:profile:$UserID:favorite_anime", $FavoriteAnimeHTML);
	  }
	  
	  ##### End Favorite Anime
	  


	  ##### Get Favorite Movies

		my $FavoriteMoviesHTML = $c->cache->get("worldofanime:profile:$UserID:favorite_movies");

    unless ($FavoriteMoviesHTML) {		    
 	  	my $FavoriteMovies = $c->model("DB::UserFavoriteMovies")->search({
    	    user_id => $UserID,
 	  	},{
		   	order_by => 'create_date ASC',
  		});

	  	while (my $fm = $FavoriteMovies->next) {
	  		$FavoriteMoviesHTML .= $fm->favorite_to_movie_title->name;
	  		$FavoriteMoviesHTML .= ", ";
	  	}
	  	
	  	$FavoriteMoviesHTML =~ s/\,$//;
	  	
		$c->cache->set("worldofanime:profile:$UserID:favorite_movies", $FavoriteMoviesHTML);
  	}
  	
  	##### End Favorite Movies



	##### Get User's Groups
	
	my $UserGroupsHTML;
	
	my $groups_json = WorldOfAnime::Controller::DAO_Groups::GetUserGroups_JSON( $c, $UserID );
	my $groups;
	
	if ($groups_json) { $groups = from_json( $groups_json ); }

	foreach my $group (@{ $groups}) {
	    my $group_id = $group->{id};
	    my $g = WorldOfAnime::Controller::DAO_Groups::GetCacheableGroupByID( $c, $group_id );
	    my $is_private  = $g->{'is_private'};
	    my $group_name  = $g->{'name'};
	    my $pretty_url  = $g->{'pretty_url'};
	
	    next if ($is_private);  # Don't show private groups here
	
	    $UserGroupsHTML .= "<a href=\"/groups/$group_id/$pretty_url\">$group_name</a>, ";
	}
	if ($UserGroupsHTML) { eval { $UserGroupsHTML =~ s/, $//; }; }
	
	#####


	  # Calculate age
	  
	  my $age;
	  if ($birthday) {
	    $birthday =~ s/(T.*$)//; # Remove timezone
	  
	    # Assuming $birth_month is 0..11
	    my ($birth_year, $birth_month, $birth_day) = split(/\-/, $birthday);
	    
	    $birth_month--; # to account for $birth_month being 0..11
	    
	
	    my ($day, $month, $year) = (localtime)[3..5];
	    $year += 1900;
	
	    $age = $year - $birth_year;
	    $age-- unless sprintf("%02d%02d", $month, $day)
		>= sprintf("%02d%02d", $birth_month, $birth_day);
	  }


    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    @image_ids = uniq(@image_ids);
    my $images_approved = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids ) &&
                          WorldOfAnime::Controller::DAO_Images::IsExternalLinksApprovedPreRender( $c, $UserCommentsHTML );

    
    $c->stash(
	images_approved => $images_approved,
	age	=> $age,
	cpager	=> $cpager,
	favorite_anime	=> $FavoriteAnimeHTML,
	favorite_movies	=> $FavoriteMoviesHTML,
	user_comments	=> $UserCommentsHTML,
	friend_status	=> $friend_status,
	friend_date	=> $friend_date,
	user_friends	=> $UserFriendsHTML,
	user		=> $u,
	profile		=> $prof,
	current_uri	=> $current_uri,
	about_me	=> $about_me,
	gender		=> $gender,
	is_self		=> $is_self,
	is_online	=> $is_online,
	join_date	=> $displayJoinDate,
	num_friends	=> $NumFriends,
	now_watching	=> $now_watching,
	now_playing	=> $now_playing,
	now_reading	=> $now_reading,
	now_doing	=> $now_doing,
	groups		=> $UserGroupsHTML,
	template	=> 'profile/profile_others.tt2',	
    );

}


sub ajax_branch1 :Path('/profile/ajax') :Args(1) {
    my ( $self, $c, $action ) = @_;
    
    if ($action eq "update_now_action") {
    	$c->forward('ajax_update_now_action');
    }

    if ($action eq "delete_now_blocks") {
        $c->forward("ajax_delete_now_blocks");
    }    
}


sub ajax_branch2 :Path('/profile/ajax') :Args(2) {
    my ( $self, $c, $action, $arg1 ) = @_;
    
    if ($action eq "load_profile_replies") {
	   $c->forward('ajax_load_profile_replies');
    }
    
    if ($action eq "load_reply") {
	   $c->forward('ajax_load_single_reply');
    }    

    if ($action eq "add_reply") {
	   $c->forward('ajax_add_reply');
    }
}


sub ajax_delete_now_blocks :Local {
    my ( $self, $c ) = @_;

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $ToUpdate = $c->model('DB::UserProfile')->find({
       user_id => $user_id,
      });
    
    $ToUpdate->update( { 
        now_watching => '',
        now_playing => '',
        now_reading => '',
        now_doing => '',
     });

    # Remove profile cache
    $c->cache->remove("worldofanime:profile:$user_id");
    
    $c->response->body("updated");    
}

sub ajax_load_profile_replies :Local {
    my ( $self, $c, $action, $parent_comment ) = @_;
    my $Body;
    
    my $latest = $c->req->param('latest');
    
    my ($latest_reply, $RepliesHTML, @image_ids) = WorldOfAnime::Controller::DAO_Users::GetProfileCommentReplies($self, $c, $parent_comment, 0, $latest );
    $Body .= "<div class=\"replies_" . $parent_comment . "\"><p> $RepliesHTML </p></div>\n" if ($RepliesHTML);
    
    $c->response->body($Body);
}

sub ajax_load_single_reply :Local {
    my ( $self, $c, $action, $id ) = @_;
    my $Body;
    
    # Get the latest reply to the parent comment
    
    my $Comment = $c->model('Comments::ProfileComment');
    $Comment->build( $c, $id );

    my $RepliesHTML = WorldOfAnime::View::HTML::display_comment($self, $c, $Comment, 3);
    $Body .= "$RepliesHTML" if ($RepliesHTML);
    
    $c->response->body($Body);
}


sub ajax_add_reply :Local {
    my ( $self, $c, $action, $parent_id ) = @_;

    my $user    = $c->req->param('user');
    my $comment = $c->req->param('post');
    my $Email;
    
    # Make sure commentor is logged in before doing this
    
    unless ($c->user_exists()) {
	$c->stash->{error_message} = "You must be logged in to add a comment.";
	$c->response->redirect("/profile/$user");  
    }

    # Figure out where the comment goes

    my $User = $c->model("DB::Users")->find({
        username => $user
    });

    my $UserID = $User->id;
    
    my $commentor_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
 
    # Who is this from?
		
    my $From = $c->model("DB::Users")->find({
    	id => $commentor_id
    });
    
    my $FromUsername = $From->username;

    # Have you blocked this user?
    if ( WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $UserID, $commentor_id )) {
	$c->stash->{error_message} = "This user has blocked you from posting on their profile.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }    

    my $Comment = $c->model("DB::UserComments")->create({
        user_id           => $UserID,
        comment_user_id   => $commentor_id,
	parent_comment_id => $parent_id,
        comment           => $comment,
        modifydate        => undef,
        createdate        => undef,        
    });
    
    my $CommentID = $Comment->id;
    
    
    ### Since this is a reply, we need to fetch everyone in the thread, and see if they want notifications.  If so, e-mail them

    my $body = <<EndOfBody;
A new reply to a comment has been added on your profile at World of Anime!

To view the reply, just go to http://www.worldofanime.com/profile/$user/reply/$CommentID

If you do not want to receive e-mail notifications when you receive a new comment anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody

    ### Figure out everyone in the loop.  Start with the original poster
    
    my %already_emailed;
    $already_emailed{$User->id} = 1;
    
    my $ReplyUsers = $c->model("DB::UserComments")->search(
	[ { parent_comment_id => $parent_id }, { id => $parent_id } ]
    );
    

    ### First, do original owner
    
		### Do they want to know about it?
		
		if ($User->user_profiles->notify_comment) {

		    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $body, 'New Profile Reply.');

		}


    ### Create Notification
 
    unless ($UserID == $commentor_id) { # Don't send yourself the notification
	WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "{p:$FromUsername} posted a <a href=\"/profile/$user/reply/$CommentID\">reply</a> to a comment in your {pw:$user}", 1);
    }
    

    ### Now, do other people in the loop want to know about it?

	my $name = $user . "'s";
	
	my $HTMLUsername = $user;
	$HTMLUsername =~ s/ /%20/g;
	
	$body = <<EndOfBody;
A new reply to a comment has been added on $name profile at World of Anime!

To view the reply, just go to http://www.worldofanime.com/profile/$HTMLUsername/reply/$CommentID

If you do not want to receive e-mail notifications when you receive a new comment anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody
    
    while (my $ru = $ReplyUsers->next) {
	next if ($already_emailed{$ru->commentors->id});
	
	### Do they want to know about notifications?
	
	if ($ru->commentors->user_profiles->notify_comment) {

	    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $ru->commentors->email, 1, $body, 'New Profile Reply.');

	}	
	
	$already_emailed{$ru->commentors->id} = 1;
	
	### Create Notification
 
	unless ($ru->commentors->id == $commentor_id) { # Don't send yourself the notification
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $ru->commentors->id, "{p:$FromUsername} posted a <a href=\"/profile/$user/reply/$CommentID\">reply</a> to a comment in $name {pw:user}", 1);
	}
    }
    

    ### Create User Action
    
    my $ActionDescription = "{p:" . $FromUsername . "} posted a <a href=\"/profile/$user/reply/$CommentID\">reply</a> to a comment on ";
    $ActionDescription   .= "{p:" . $User->username . "}'s profile";
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $commentor_id,
	action_id => 2,
	action_object => $UserID,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    # Clear this comment (and its parent) from memcached
    
    my $NewComment = $c->model('Comments::ProfileComment');
    $NewComment->build( $c, $CommentID );
    $NewComment->clear( $c );
    
    $c->response->body($CommentID);
}




sub profile_branch2 :Path('/profile') :Args(2) {
    my ( $self, $c, $user, $action ) = @_;
    
    if ($action eq "add_comment") {
        $c->forward('add_comment');
    }
    
    if ($action eq "reply_comment") {
	$c->forward('reply_comment');
    }
    
    if ($action eq "friend_request") {
        $c->forward('friend_request');
    }

    if ($action eq "gallery") {
	$c->detach('WorldOfAnime::Controller::ImageGalleries', 'view_all_image_galleries', [ $user, $action ]);
    }

    if ($action eq "friends") {
        $c->detach('view_friends');
    }

    if ($action eq "groups") {
        $c->detach('view_groups');
    }

    if ($action eq "refer") {
        $c->detach('view_referrals');
    }
    
    if ($action eq "update_now_watching") {
	$c->detach('update_now_watching');
    }

    if ($action eq "update_now_playing") {
	$c->detach('update_now_playing');
    }
    
    if ($action eq "update_now_reading") {
	$c->detach('update_now_reading');
    }
    
    if ($action eq "update_now_doing") {
	$c->detach('update_now_doing');
    }    
    

    # For historical purposes, the following URL is ok, too
    if ($action eq "image_gallery") {
        $c->detach('WorldOfAnime::Controller::ImageGalleries', 'view_all_image_galleries', [ $user, $action ]);
    }

    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();
}


sub profile_branch3 :Path('/profile') :Args(3) {
    my ( $self, $c, $user, $action1, $action2 ) = @_;
    
    if ($action1 eq "images") {
	$c->detach('WorldOfAnime::Controller::ImageGalleries', 'view_image', [ $user, $action1, $action2 ]);
    }
    
    if ( ($action1 eq "gallery") && ($action2 =~ /(\d+)/) ) {
	$c->detach('WorldOfAnime::Controller::ImageGalleries', 'view_single_image_gallery', [ $user, $action1, $action2 ]);
    }
    
    if ( ($action1 eq "gallery") && ($action2 eq "add_gallery") ) {
	$c->forward('WorldOfAnime::Controller::ImageGalleries', 'add_gallery', [ $user, $action1, $action2 ]);
    }
    
    if ( ($action1 eq "refer") && ($action2 eq "add_new_referral") ) {
        $c->detach('add_new_referral');
    }
    
    if ($action1 eq "comment") {
	$c->detach('view_individual_comment');
    }
    
    
    # NOTE: If we ever change replies to have their own table, we must add a new subroutine view_individual_reply and use that, since comment_id and reply_id could clash
    # For now its ok, since we use the same table for comments and replies
    if ($action1 eq "reply") {
	$c->detach('view_individual_comment');
    }    
    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();    

}


sub profile_branch4 :Path('/profile') :Args(4) {
    my ( $self, $c, $user, $action1, $action2, $action3 ) = @_;
    
    if ( ($action1 eq "images") && ($action3 eq "add_comment") )
    {
	$c->forward('WorldOfAnime::Controller::ImageGalleries', 'add_comment_image', [ $user, $action1, $action2, $action3 ]);
    }
    
    if ( ($action1 eq "images") && ($action3 eq "delete") )
    {
	$c->forward('WorldOfAnime::Controller::ImageGalleries', 'delete_image', [ $user, $action1, $action2, $action3 ]);
    }    

    if ( ($action1 eq "images") && ($action3 eq "update_image") )
    {
	$c->forward('WorldOfAnime::Controller::ImageGalleries', 'update_image', [ $user, $action1, $action2, $action3 ]);
        #$c->forward('update_image');
    }

    if ( ($action1 eq "images") && ($action3 eq "set_profile_image") )
    {
        $c->forward('set_profile_image');
    }
    
    
    if ( ($action1 eq "gallery") && ($action2 =~ /(\d+)/) && ($action3 eq "add_image") ) {
	$c->forward('WorldOfAnime::Controller::ImageGalleries', 'add_image', [ $user, $action1, $action2, $action3 ]);
    }
    
    if ( ($action1 eq "gallery") && ($action2 =~ /(\d+)/) && ($action3 eq "update_gallery") ) {
	$c->forward('WorldOfAnime::Controller::ImageGalleries', 'update_gallery', [ $user, $action1, $action2, $action3 ]);
    }    

    if ( ($action1 eq "gallery") && ($action2 =~ /(\d+)/) && ($action3 eq "delete_gallery") ) {
	$c->forward('WorldOfAnime::Controller::ImageGalleries', 'delete_gallery', [ $user, $action1, $action2, $action3 ]);
    }    
    
    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();    
}



sub add_comment :Local {
    my ( $self, $c, $user, $action ) = @_;
    my $body;
    my $Email;

    # Make sure commentor is logged in before doing this
    
    unless ($c->user_exists()) {
	$c->stash->{error_message} = "You must be logged in to add a comment.";
	$c->response->redirect("/profile/$user");  
    }
    
    # Figure out where the comment goes

    my $User = $c->model("DB::Users")->find({
        username => $user
    });

    my $UserID = $User->id;
    
    my $comment = $c->req->param('comment');
    my $commentor_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
 
    # Who is this from?
		
    my $From = $c->model("DB::Users")->find({
    	id => $commentor_id
    });
    
    my $FromUsername = $From->username;
    
    
    # Have you blocked this user?
    if ( WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $UserID, $commentor_id ) ) {
	$c->stash->{error_message} = "This user has blocked you from posting on their profile.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }    
        
    
    my $Comment = $c->model("DB::UserComments")->create({
        user_id         => $UserID,
        comment_user_id => $commentor_id,
        comment         => $comment,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    my $CommentID = $Comment->id;
    

		# Do they want to know about it?
		
		if ($User->user_profiles->notify_comment) {
		    
		my $HTMLUsername = $user;
		$HTMLUsername =~ s/ /%20/g;

	$body = <<EndOfBody;
You have received a new comment on your profile at World of Anime!

To view your new comment, just go to http://www.worldofanime.com/profile/$HTMLUsername/comment/$CommentID

if you do not want to receive e-mail notifications when you receive a new comment anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody
    
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $body, 'New Profile Comment.');

		}

    ### Create Notification
 
    unless ($UserID == $commentor_id) { # Don't send yourself the notification
	WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "{p:$FromUsername} left a <a href=\"/profile/$user/comment/$CommentID\">comment</a> on your {pw:$user}", 1);
    }
    
    ### Create User Action
    
    my $ActionDescription = "{p:" . $FromUsername . "} posted a <a href=\"/profile/$user/comment/$CommentID\">comment</a> on ";
    $ActionDescription   .= "{p:" . $User->username . "}'s profile";
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $commentor_id,
	action_id => 2,
	action_object => $UserID,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    ### End User Action
    
    $c->response->redirect("/profile/$user");  
}



sub friend_request :Local {
    my ( $self, $c, $user, $action ) = @_;
    my $body;
    my $Email;

    # Figure out where the request goes

    my $User = $c->model("DB::Users")->find({
        username => $user
    });

    my $UserID = $User->id;
    my $UserUsername = $User->username;
    my $UserEmail    = $User->email;
    
    my $friend_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    
    my $Request = $c->model("DB::UserFriends")->create({
        user_id         => $UserID,
        friend_user_id  => $friend_id,
        status          => 1,
        modifydate      => undef,
        createdate      => undef,        
    });
 
      # Now send the user their e-mail, if they want


    if ($User->user_profiles->notify_friend_request) {      

    my $FriendUser = $c->model("DB::Users")->find({
        id => $friend_id,
    });

    my $FriendUsername = $FriendUser->username;

	$body = <<EndOfBody;
Dear $UserUsername,

$FriendUsername has requested to be your friend at World of Anime!

To view your Friend Requests, please log in and go to http://www.worldofanime.com/friend_requests
EndOfBody
    
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $UserEmail, 1, $body, 'New Friend Request.');
		
  }


    ### Create User Action
    
    my $ActionDescription = "{p:" . $Request->friends->username . "} has made a friend request";
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Request->friends->id,
	action_id => 9,
	action_object => $UserID,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    ### End User Action
    
    WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "{p:" . $Request->friends->username . "} has requested to be your <a href=\"/friend_requests\">friend</a>.", 5);
    
    # Update Friend Status
    WorldOfAnime::Controller::DAO_Friends::FriendStatusChange( $c, $UserID, $friend_id);
    
    # This is so the person will see their new friend request
    $c->cache->remove("worldofanime:num_friend_requests:$UserID");
    
    $c->response->redirect("/profile/$user");  
}



sub update_image :Local {
    my ( $self, $c, $user, $action, $id ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit an image.");

    my $image = $c->model('DB::GalleryImages')->find( {
	id => $id,
    });
    
    my $owner = $image->image_images->user_id;
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($UserID == $owner) {
	$c->stash->{error_message} = "Huh?  This isn't your image.  Wait, how did you get here?";
        $c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
	
    
    # If they made it here, its ok to modify the image
    
    # Lets store the gallery_id, in case they changed it
    # we need to update the image count on new and old gallery
    
    my $old_gallery_id = $image->gallery_id;
    
    my $title = $c->req->params->{title};
    my $desc  = $c->req->params->{description};
    my $new_gallery_id = $old_gallery_id;
    
    if ($c->req->params->{move_to_gallery}) {
	$new_gallery_id = $c->req->params->{move_to_gallery};
    }

    $image->update({
	title => $title,
	description => $desc,
	gallery_id => $new_gallery_id,
    });
    
    # Did they update the gallery id?
    
    unless ($new_gallery_id == $old_gallery_id) {
	# Subtract 1 from old gallery, and add 1 to new gallery

	my $OldGallery = $c->model('Galleries::Gallery');
	$OldGallery->build( $c, $old_gallery_id );
	$OldGallery->update_image_count( $c, $OldGallery->num_images - 1);
	$OldGallery->clear( $c );
	$c->cache->remove("woa:gallery:latest_image:$old_gallery_id");
	
	my $NewGallery = $c->model('Galleries::Gallery');
	$NewGallery->build( $c, $new_gallery_id );
	$NewGallery->update_image_count( $c, $NewGallery->num_images + 1);
	$NewGallery->clear( $c );
	$c->cache->remove("woa:gallery:latest_image:$new_gallery_id");

    }
    
    WorldOfAnime::Controller::DAO_Images::CleanGalleryImage( $c, $id );
    
    $c->response->redirect("/profile/$user/images/$id"); 
}


sub set_profile_image :Local {
    my ( $self, $c, $user, $action, $id ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to do this.");

    my $image = $c->model('DB::GalleryImages')->find( {
	id => $id,
    });
    
    my $owner = $image->image_images->user_id;
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($UserID == $owner) {
	$c->stash->{error_message} = "Huh?  This isn't your image.  Wait, how did you get here?";
        $c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
	
    
    # If they made it here, its ok to set

    my $profile = $c->model('DB::UserProfile')->find({
	user_id => $UserID,
    });
    
    $profile->update({
	profile_image_id => $image->image_id,
    });

    
    # Remove cache, so new image shows up
    WorldOfAnime::Controller::DAO_Users::UserCleanup( $c, $UserID, $user);
	
    $c->response->redirect("/profile/$user/images/$id"); 
}


# Friend Stuff

sub view_friends :Local {
    my ( $self, $c, $user ) = @_;

    # Try to get a user profile

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID   = $u->{'id'};

    if ($UserID) {
    
        my $is_self;
        my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
        if ($viewer_id == $UserID) { $c->stash->{is_self} = 1; }     

        $c->stash->{user}         = $u;
    }
    
    $c->stash->{template}     = 'profile/profile_friends.tt2';
}




# Groups Stuff

sub view_groups :Local {
    my ( $self, $c, $user ) = @_;

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $is_self;
    
    my $cpage = $c->req->params->{'cpage'} || 1;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Try to get a user profile

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID         = $u->{'id'};
    
    if ($viewer_id == $UserID) { $is_self = 1; }    
    
    my $GroupsHTML;

    my $groups;
    my $groups_json = WorldOfAnime::Controller::DAO_Groups::GetUserGroups_JSON( $c, $UserID );
    if ($groups_json) { $groups = from_json( $groups_json ); }

    foreach my $group (@{ $groups}) {

	my $g =$c->model('Groups::Group');
	$g->build( $c, $group->{id} );
	$g->get_group_profile_image( $c );

	my $i = $c->model('Images::Image');
	$i->build($c, $g->profile_image_id);
        my $thumb_url = $i->thumb_url;
	
	my $GroupID = $g->id;
	my $create_date = $g->createdate;
	my $groupdesc   = $g->description;
	my $groupname   = $g->name;
	my $prettyurl   = $g->pretty_url;
	
	my $m = $c->model('Groups::GroupMembers');
	$m->build( $c, $GroupID );
	my $members;
	my $num_members = 0;
    
	if ($m->members) {
	    $members = from_json( $m->members );
	    $num_members = $m->member_count;
	}	
	
	my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID);	

	my $displayCreateDate = WorldOfAnime::Controller::Root::PrepareDate($create_date, 1);
	$groupdesc =~ s/\n/<br \/>/g;
        
        $GroupsHTML .= "<div id=\"top_user_profile_box\">\n";
	$GroupsHTML .= "<table border=\"0\">\n";
	if ($IsOwner) {
	    $GroupsHTML .= "	<tr><td colspan=\"2\"><span class=\"group_info\">You are the owner of this group</span></td></tr>";
	} elsif ($IsAdmin) {
	    $GroupsHTML .= " <tr><td colspan=\"2\"><span class=\"group_info\">You are an admin of this group</span></td></tr>";
	}
	$GroupsHTML .= "	<tr>\n";
	$GroupsHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
	$GroupsHTML .= "			<a href=\"/groups/$GroupID/$prettyurl\"><img src=\"$thumb_url\" border=\"0\"></a>";
	$GroupsHTML .= "		</td>\n";
	$GroupsHTML .= "		<td valign=\"top\" width=\"560\">\n";
	$GroupsHTML .= "			<span class=\"group_name_link\"><a href=\"/groups/$GroupID/$prettyurl\">$groupname</a></span><br />\n";
        $GroupsHTML .= "                        <span class=\"top_user_profile_date\">+$num_members members<p />\n";
        $GroupsHTML .= "                        <span class=\"group_description\">$groupdesc</span>\n";
	$GroupsHTML .= "		</td>\n";
	$GroupsHTML .= "	</tr>\n";
	$GroupsHTML .= "	<tr>\n";
	$GroupsHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Created on $displayCreateDate</span></td>\n";
	$GroupsHTML .= "	</tr>\n";
	$GroupsHTML .= "</table>\n";
	$GroupsHTML .= "</div>\n\n";
	$GroupsHTML .= "<p />\n";
    }
    
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff


    $c->stash->{GroupsHTML}  = $GroupsHTML;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{is_self}     = $is_self;
    $c->stash->{user}        = $u;
    $c->stash->{template} = 'profile/profile_groups.tt2';
}



# Groups Stuff

sub view_groups_with_pending_members :Path('/group_requests') {
    my ( $self, $c ) = @_;
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $message = "You currently have no friend requests";
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your groups.");


    # Try to get a user profile

    my $User = $c->model("DB::Users")->find({
        id => $UserID
    });
    
    my $user = $User->username;
    
    my $i = $c->model('Images::Image');
    $i->build($c, $User->user_profiles->user_profile_image_id->id);
    my $profile_image_url = $i->thumb_url;    
    
    my $GroupsHTML;
    
    my $UserGroups = WorldOfAnime::Controller::DAO_Groups::GetUserGroups( $c, $UserID );

    
    while (my $group = $UserGroups->next) {

        my $GroupID     = $group->group_id->id;
	
        my $g = WorldOfAnime::Controller::DAO_Groups::GetCacheableGroupByID( $c, $group->group_id->id );

        my $groupname        = $g->{'name'};
        my $groupdesc  = $g->{'description'};
        my $prettyurl   = $g->{'pretty_url'};
        my $num_members = $g->{'num_members'};
	my $creator_id  = $g->{'created_by'};
	my $create_date = $g->{'create_date'};
	
	my $i = $c->model('Images::Image');
        $i->build($c, $g->{'profile_image_id'});
	my $group_profile_image_url = $i->thumb_url;   	

	my $displayCreateDate = WorldOfAnime::Controller::Root::PrepareDate($create_date, 1);
        $groupdesc =~ s/\n/<br \/>/g;

        if ( ($UserID == $creator_id) || ($group->is_admin) ) {
	    
	    my $NumJoinRequests = WorldOfAnime::Controller::DAO_Groups::GetNumJoinRequests( $c, $GroupID );
	    next unless ($NumJoinRequests > 0);
	    
            $GroupsHTML .= "<div id=\"top_user_profile_box\">\n";
	    $GroupsHTML .= "<table border=\"0\">\n";
	    $GroupsHTML .= "	<tr>\n";
	    $GroupsHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
	    $GroupsHTML .= "			<a href=\"/groups/$GroupID/$prettyurl/join_requests\"><img src=\"$group_profile_image_url\" border=\"0\"></a>";
	    $GroupsHTML .= "		</td>\n";
	    $GroupsHTML .= "		<td valign=\"top\" width=\"560\">\n";
	    $GroupsHTML .= "			<span class=\"group_name_link\"><a href=\"/groups/$GroupID/$prettyurl/join_requests\" title=\"$NumJoinRequests Pending\">$groupname</a></span><br />\n";
	    $GroupsHTML .= "                        <span class=\"top_user_profile_date\">+$num_members members<p />\n";
	    $GroupsHTML .= "                        <span class=\"group_description\">$groupdesc</span>\n";
	    $GroupsHTML .= "		</td>\n";
	    $GroupsHTML .= "	</tr>\n";
	    $GroupsHTML .= "	<tr>\n";
	    $GroupsHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Created on $displayCreateDate</span></td>\n";
	    $GroupsHTML .= "	</tr>\n";
	    $GroupsHTML .= "</table>\n";
	    $GroupsHTML .= "</div>\n\n";
	    $GroupsHTML .= "<p />\n";
	}
    }
    
    
    my $HeaderHTML;

    $HeaderHTML .= "<div id=\"plain_user_profile_box\">\n";
    $HeaderHTML .= "<table border=\"0\">\n";
    $HeaderHTML .= "	<tr>\n";
    $HeaderHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
    $HeaderHTML .= "			<a href=\"/profile/$user\"><img src=\"$profile_image_url\" border=\"0\"></a>";
    $HeaderHTML .= "		</td>\n";
    $HeaderHTML .= "		<td valign=\"top\" width=\"360\">\n";
    $HeaderHTML .= "			<span class=\"plain_user_profile_name\">$user\'s Groups</span><br />\n";
    $HeaderHTML .= "		</td>\n";
    $HeaderHTML .= "		<td valign=\"top\">\n";
    $HeaderHTML .= "		</td>\n";
    $HeaderHTML .= "	</tr>\n";
    $HeaderHTML .= "</table>\n";
    $HeaderHTML .= "</div>\n\n";
    $HeaderHTML .= "<p />\n";      
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff


    $c->stash->{GroupsHTML}  = $GroupsHTML;
    $c->stash->{header_html} = $HeaderHTML;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'profile/group_requests.tt2';
}



# Referral Stuff

sub view_referrals :Local {
    my ( $self, $c, $user ) = @_;

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $is_self;
    
    my $cpage = $c->req->params->{'cpage'} || 1;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Try to get a user profile

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID   = $u->{'id'};    
    
    if ($viewer_id == $UserID) { $is_self = 1; }    


    my $Referrals = $c->model('DB::Users')->search({
	referred_by => $UserID,
    });
    
    my $ReferralCount = 0;
    my $ReferralsHTML;
    
    while (my $r = $Referrals->next) {
	$ReferralCount++;
	my $username = $r->username;
	
	my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $r->id );
        my $profile_image_id = $p->profile_image_id;
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;

	my $points   = $r->points;
	my $join_date = $r->confirmdate;
	my $displayJoinDate = WorldOfAnime::Controller::Root::PrepareDate($join_date, 1, $tz);

	my $image_gallery_link;
	
	# If we decide to only show the image gallery link to people who have it in the preferences, uncomment the if / }
	#if ($member->user_profiles->show_gallery_to_all) {
	    $image_gallery_link = "<span class=\"top_user_profile_link\"><a href=\"/profile/$username/gallery\">Image Gallery</a></span><br />\n";
	#}
	
	$ReferralsHTML .= "<div id=\"top_user_profile_box\">\n";
	$ReferralsHTML .= "<table border=\"0\">\n";
	$ReferralsHTML .= "	<tr>\n";
	$ReferralsHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
	$ReferralsHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a>";
	$ReferralsHTML .= "		</td>\n";
	$ReferralsHTML .= "		<td valign=\"top\" width=\"360\">\n";
	$ReferralsHTML .= "			<span class=\"top_user_profile_name\"><a href=\"/profile/$username\">$username</a></span><br />\n";
	$ReferralsHTML .= "			<span class=\"top_user_profile_points\">+$points points</span>\n";
	$ReferralsHTML .= "		</td>\n";
	$ReferralsHTML .= "		<td valign=\"top\">\n";
	$ReferralsHTML .= "			<span class=\"top_user_profile_link\"><a href=\"/profile/$username\">Profile</a></span><br />\n";
	$ReferralsHTML .= "			$image_gallery_link";
	$ReferralsHTML .= "			<span class=\"top_user_profile_link\"><a href=\"/blogs/$username\">Blog</a></span><br />\n";
	$ReferralsHTML .= "		</td>\n";
	$ReferralsHTML .= "	</tr>\n";
	$ReferralsHTML .= "	<tr>\n";
	$ReferralsHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Joined $displayJoinDate</span></td>\n";
	$ReferralsHTML .= "	</tr>\n";
	$ReferralsHTML .= "</table>\n";
	$ReferralsHTML .= "</div>\n\n";
	$ReferralsHTML .= "<p />\n";	
    }
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff


    $c->stash->{current_uri}   = $current_uri;
    $c->stash->{is_self}       = $is_self;
    $c->stash->{user}          = $u;
    $c->stash->{ReferralsHTML} = $ReferralsHTML;
    $c->stash->{referral_count} = $ReferralCount;
    $c->stash->{template} = 'profile/referrals.tt2';
}


sub add_new_referral :Local {
    my ( $self, $c, $user, $action1, $action2 ) = @_;
    my $is_self;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Try to get a user profile

    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByUsername($c, $user);

    my $UserID = $User->id;
    
    if ($viewer_id == $UserID) { $is_self = 1; }
    
    unless ($is_self) {
	    $c->stash->{error_message} = "What?  You can't do that!";
	    $c->stash->{template}      = 'error_page.tt2';
	    $c->detach();
    }

    my $email   = $c->req->params->{'referral_email'};
    my $text    = $c->req->params->{'referral_text'};
    my $subject = $c->req->params->{'subject'};
    
    $text .= "\nTo join World of Anime, please use the following link - http://www.worldofanime.com/refer/$user";
    
    if ($email) {
    
	# Make sure they aren't on the suppression list
    
	unless (WorldOfAnime::Controller::DAO_Email::IsSuppressed($c, $email)) {
    
	    # Make sure they aren't already a user
	
	    unless (WorldOfAnime::Controller::DAO_Email::IsUser($c, $email)) {
    
	        # Make sure they haven't been referred by this person already
	    
	        unless (WorldOfAnime::Controller::DAO_Email::IsReferred($c, $email, $UserID)) {

		    my $Referral = $c->model('Anime::Referrals')->create({
		        user_id       => $UserID,
		        referral      => $email,
		        referral_text => $text,
		    });
    
		    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $email, 1, $text, $subject);
		}
	    }
	}
    }

   $c->response->redirect("/profile/$user/refer");
   $c->detach();    
}




sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    my $errors = scalar @{$c->error};

    foreach my $error (@{$c->error}) {
        if ( ($error =~ /.*/) )  # We can use this to forward to different error pages later, if we want
        {
        	my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
        		
        	if ($viewer_id != 3) { # This is me, show me the real error
			$c->clear_errors;
			$c->stash->{template} = 'custom_error.tt2';
		}
        }
    }
}



1;
