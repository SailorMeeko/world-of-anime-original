package WorldOfAnime::Controller::Notifications;

use strict;
use warnings;
#use Time::Duration;
#use Date::Calc qw( check_date Decode_Date_US Today leap_year Delta_Days );
use parent 'Catalyst::Controller';


### Your notifications ###

sub view_profile_self :Path('/notifications') {
    my ( $self, $c ) = @_;
    my @image_ids;

    # Check to make sure they are logged in, or show error
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your notifications.");

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    push (@image_ids, $u->{'background_profile_image_id'});    

    # Reset notifications to 0

    my $Unviewed = $c->model('DB::Notifications')->search({
	-and => [ user_id => $user_id,
	    viewed => 0,
	],
    });
    
    $Unviewed->update({
	viewed => 1,
    });

    # Set memcached to 0
    
    my $cid = "worldofanime:notifications:$user_id";
    $c->cache->set($cid, 0, 2592000);
    
    my $page = $c->req->params->{'page'} || 1;
    
    my $Notifications = $c->model("DB::Notifications")->search({
        user_id => $user_id,
    },{
      page      => "$page",
      rows      => 25,
      order_by  => 'create_date DESC',
      });
    
    my $pager = $Notifications->pager();

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{pager}    = $pager;    
    $c->stash->{Notifications} = $Notifications;
    $c->stash->{template} = "notifications/notifications.tt2";
}

sub check :Path('/notifications/check') :Args(0) {
    my ( $self, $c ) = @_;
    my $text = " ";
    my $num_notifications = 0;

    if ( $c->user_exists() ) {
         my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
        # Check memcached
    
        my $cid = "worldofanime:notifications:$user_id";
        $num_notifications = $c->cache->get($cid);
    
        unless (defined($num_notifications)) {
	    my $Notifications = $c->model('DB::Notifications')->search({
		-and => [ user_id => $user_id,
			viewed => 0,
			],
	    });
	    
	    if ($Notifications->count) {
		$num_notifications = $Notifications->count;
		$c->cache->set($cid, $num_notifications, 2592000);	
	    }
	    
	}
    }
    
    if (defined($num_notifications) && ($num_notifications > 0) ) {
        $text = "(" . $num_notifications . " New)";
    }
    
    $c->response->body($text);
}


sub delete :Path('/notifications/delete') {
    my ( $self, $c ) = @_;
    
    my $note = $c->req->params->{note};
    
    # Check to make sure this is their notification
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $Notification = $c->model("DB::Notifications")->find({
        id => $note,
    });
    
    if (defined($Notification)) {
	if ($user_id == $Notification->user_id) {
	    $Notification->delete;
        }
    }
}


sub delete_all :Path('/notifications/delete_all') {
    my ( $self, $c ) = @_;
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $Notifications = $c->model("DB::Notifications")->search({
	user_id => $user_id,
    });
    
    $Notifications->delete;
    
    $c->response->redirect("/notifications");
}


sub AddNotification : Local {
    my ( $c, $user_id, $notification, $type, $force ) = @_;
    
    # Pass a non zero value to $force in order to force the notification regardless of user settings
    # (use very carefully)
    
    ### Notification Types
    # 1 = comment
    # 2 = image posted
    # 3 = blog posted
    # 4 = private message
    # 5 = friend request
    # 6 = friend removal
    # 7 = deleted comment
    # 8 = subscription
    # 9 = question posted
    # 10 = friend request accepted
    # 11 = friend request rejected
    # 12 = new forum thread
    # 13 = unsubscription
    # 14 = new answer
    # 15 = now watching
    # 16 = now playing
    # 17 = now reading
    # 18 = now doing
    # 19 = new group
    # 20 = group invite
    # 21 = accept group invite
    # 22 = reject group invite
    # 23 = join group
    # 24 = group promoted to admin
    # 25 = group demoted from admin
    # 26 = removed from group
    # 27 = group join request
    # 28 = group image comment
    # 29 = New referral
    # 30 = Added image to favorites
    # 31 = Removed image from favorites
    # 32 = Tagged a gallery image
    # 33 = Removed a tag from a gallery image
    # 34 = Writes a new fan fiction chapter
    # 35 = Writes a new review
    # 36 = Group comment
    # 37 = Group member leaves

    my $cid = "worldofanime:notifications:$user_id";

    # Does this person want this notification?
    
    if ( ($force) || ( WorldOfAnime::Controller::Notifications::WantsNotification( $c, $user_id, $type ) ) ) {

        $c->model('DB::Notifications')->create({
	    user_id => $user_id,
	    notification_type => $type,
	    notification => $notification,
	    create_date => undef,
	});

	$c->cache->remove($cid);
    }
    
    return 1;
}


sub AllSiteNotifications {
    my ( $c ) = @_;

    return ( 'notify_site_comment',
	     'notify_site_group_comment',
	     'notify_site_images',
	     'notify_site_blog',
	     'notify_site_pm',
	     'notify_site_friend_request',
	     'notify_site_subscription',
	     'notify_site_favorites',
	     'notify_site_tag',
	     'notify_site_questions',
	     'notify_site_threads',
	     'notify_site_now_actions',
	     'notify_site_new_group',
	     'notify_site_fan_fiction',
	     'notify_site_friend_new_review',
	     'notify_site_group_joins',
	     'notify_site_group_membership',
	     'notify_site_referral',
	     );
}


sub SiteNotificationMap {
    my %map;
    
    %map = ( 1 => 'notify_site_comment',
	     2 => 'notify_site_images',
	     3 => 'notify_site_blog',
	     4 => 'notify_site_pm',
	     5 => 'notify_site_friend_request',
	     6 => 'notify_site_friend_request',
	     7 => 'notify_site_comment',
	     8 => 'notify_site_subscription',
	     9 => 'notify_site_questions',
	     10 => 'notify_site_friend_request',
	     11 => 'notify_site_friend_request',
	     12 => 'notify_site_threads',
	     13 => 'notify_site_subscription',
	     14 => 'notify_site_subscription',
	     15 => 'notify_site_now_actions',
	     16 => 'notify_site_now_actions',
	     17 => 'notify_site_now_actions',
	     18 => 'notify_site_now_actions',
	     19 => 'notify_site_new_group',
	     20 => 'notify_site_group_membership',
	     21 => 'notify_site_group_membership',
	     22 => 'notify_site_group_membership',
	     23 => 'notify_site_group_membership',
	     24 => 'notify_site_group_membership',
	     25 => 'notify_site_group_membership',
	     26 => 'notify_site_group_membership',
	     27 => 'notify_site_group_membership',
	     28 => 'notify_site_comment',
	     29 => 'notify_site_referral',
	     30 => 'notify_site_favorites',
	     31 => 'notify_site_favorites',
	     32 => 'notify_site_tag',
	     33 => 'notify_site_tag',
	     34 => 'notify_site_fan_fiction',
	     35 => 'notify_site_friend_new_review',
	     36 => 'notify_site_group_comment',
	     37 => 'notify_site_group_membership',
	     );
    
    return \%map;
}


sub WantsNotification :Local {
    my ( $c, $user_id, $type ) = @_;
    
    # Which notification group does this belong to?
    
    my $map = WorldOfAnime::Controller::Notifications::SiteNotificationMap();
    
    my $notification = $map->{$type};
    
    # Check memcached for an explicit 0

    my $cid = "worldofanime:site_notification:$notification:$user_id";
    my $pref = $c->cache->get($cid);
    
    if ( defined($pref) ) {
	if ($pref == 0) {
	    return 0;
	} elsif ($pref == 1) {
	    return 1;
	}
    }

    
    # If not in memcached, check DB
    
    my $PrefDB = $c->model('DB::UserProfileSiteNotifications')->search({
		user_id => $user_id,
		notification => $notification,
    });

    if ($PrefDB->count) {
	my $record = $PrefDB->first;
	my $receive = $record->receive;
	# If it is in the database, set it and cache it for 30 days

	$c->cache->set($cid, $receive, 2592000);
	return $receive;

    } else {
	# If it is not in the database, manually set it to 1, set it, and cache it for 30 days
	my $NewPref = $c->model('DB::UserProfileSiteNotifications')->update_or_create({
	    user_id => $user_id,
	    notification => $notification,
	    receive => 1,
	},{ key => 'user_notification' });

	$c->cache->set($cid, 1, 2592000);
	return 1;
    }
    
    # If we get here, they haven't set this pref.  Assume 1
    
    $c->cache->set($cid, 1, 2592000);
    return 1;
}



sub MultiNotify : Local {
    my ( $self, $c, $notification, $type, $friends, $subscribers ) = @_;
    
    my %Notified;
    
    if ($friends) {
        foreach my $f (@{ $friends}) {

            WorldOfAnime::Controller::Notifications::AddNotification($c, $f->{id}, $notification, $type);
            $Notified{$f->{id}} = 1;

        }
    }

    if ($subscribers) {
        foreach my $sub (@{ $subscribers}) {
            next if ($Notified{$sub->{user_id}});
        
            WorldOfAnime::Controller::Notifications::AddNotification($c, $sub->{user_id}, $notification, $type);
            $Notified{$sub->{user_id}} = 1;
        }
    }
}



sub SiteNotificationsClearCache {
    my ( $c ) = @_;
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);    
    
    my @NotificationList = WorldOfAnime::Controller::Notifications::AllSiteNotifications($c);
    
    foreach my $notification (@NotificationList) {
	my $cid = "worldofanime:site_notification:$notification:$UserID";
	$c->cache->remove($cid);
    }
}


sub PopulateNotificationPrefs {
    my ( $c ) = @_;
    my $ref;
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # This routine is used to check for the existence of a site notification for a user
    
    my @NotificationList = WorldOfAnime::Controller::Notifications::AllSiteNotifications($c);
    
    foreach my $notification (@NotificationList) {
    
	# If it exists in cache, set it
	
	my $cid = "worldofanime:site_notification:$notification:$UserID";
	my $pref = $c->cache->get($cid);
	$ref->{$notification} = $pref;
    
	# If it does not exist in cache, check in the database
	
	unless ( defined($pref) ) {
	    my $PrefDB = $c->model('DB::UserProfileSiteNotifications')->search({
		user_id => $UserID,
		notification => $notification,
	    });
	    
	    
	    if ($PrefDB->count) {
		my $record = $PrefDB->first;
		my $receive = $record->receive;
		# If it is in the database, set it and cache it for 30 days
		
		$ref->{$notification} = $receive;
		$c->cache->set($cid, $receive, 2592000);
		
	    } else {
		# If it is not in the database, manually set it to 1, set it, and cache it for 30 days
		my $NewPref = $c->model('DB::UserProfileSiteNotifications')->update_or_create({
		    user_id => $UserID,
		    notification => $notification,
		    receive => 1,
		},{ key => 'user_notification' });
		
		$ref->{$notification} = 1;
		$c->cache->set($cid, 1, 2592000);
	    }
	}
	
	
    }
    
    return $ref;
}


1;