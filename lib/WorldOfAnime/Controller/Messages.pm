package WorldOfAnime::Controller::Messages;
use Moose;
use JSON;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


sub view_single_private_message :Path('/pm') :Args(1) {
    my ( $self, $c, $message_id ) = @_;
    my @image_ids;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your private messages.");     

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $PM = $c->model('Messages::PrivateMessage');
    $PM->build( $c, $message_id );
    
    unless ($PM->user_id == $user_id ) {
	# Have to die here, this isn't their message
	
	$c->stash->{error_message} = "This doesn't appear to be one of your private messages.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();	
    }

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    push (@image_ids, $u->{'background_profile_image_id'});    

    my $p = $c->model('Users::UserProfile');
    $p->get_profile_image( $c, $PM->from_user_id );
    push (@image_ids, $p->profile_image_id);
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );    
    $c->stash->{message}   = $PM;
    $c->stash->{template}  = 'messages/single_private_message.tt2';
}


sub view_thread :Path('/pm/thread') :Args(1) {
    my ( $self, $c, $thread_id ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your private messages.");
    
    my $Thread = $c->model('Messages::Thread');
    $Thread->build( $c, $thread_id );
    
    $c->stash->{thread}    = $Thread;
    $c->stash->{template}  = 'messages/thread.tt2';    
}



sub view_private_messages :Path('/pm') :Args(0) {
    my ( $self, $c ) = @_;
    my @image_ids;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your private messages.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    push (@image_ids, $u->{'background_profile_image_id'});
    
    ##### Get Private Messages

    my $pms = $c->model('Messages::UserMessages');
    $pms->build( $c, $user_id );
    $pms->populate_all( $c );

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{pms}   = $pms;
    $c->stash->{template}  = 'messages/view_private_messages.tt2';	
}



sub view_sent_private_messages :Path('/pm/sent') :Args(0) {
    my ( $self, $c ) = @_;
    my @image_ids;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your sent private messages.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    push (@image_ids, $u->{'background_profile_image_id'});    
    
    ##### Get Private Messages Sent

    my $pms = $c->model('Messages::UserMessages');
    $pms->build( $c, $user_id );
    $pms->populate_sent( $c );    

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{pms}   = $pms;
    $c->stash->{template}  = 'messages/view_private_messages_sent.tt2';	    
}


sub view_single_sent_private_message :Path('/pm/sent') :Args(1) {
    my ( $self, $c, $message_id ) = @_;
    my @image_ids;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your private messages.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $PM = $c->model('Messages::PrivateMessage');
    $PM->build( $c, $message_id );
    
    unless ($PM->from_user_id == $user_id ) {
	# Have to die here, this isn't their message

	$c->stash->{error_message} = "This doesn't appear to be one of your sent private messages.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();		
    }
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    push (@image_ids, $u->{'background_profile_image_id'});

    my $p = $c->model('Users::UserProfile');
    $p->get_profile_image( $c, $PM->from_user_id );
    push (@image_ids, $p->profile_image_id);
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );        
    $c->stash->{message}   = $PM;
    $c->stash->{sent_screen} = 1;
    $c->stash->{template}  = 'messages/single_private_message.tt2';
}



sub view_private_messages_from_user :Path('/pm/from') :Args(1) {
    my ( $self, $c, $from_user_id ) = @_;
    my @image_ids;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your private messages.");
    
    my $User = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $FromUser = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $from_user_id );
    
    my $p = $c->model('Users::UserProfile');
    $p->get_profile_image( $c, $from_user_id );
    my $profile_image_id = $p->profile_image_id;
    push (@image_ids, $User->{'background_profile_image_id'});    
    push (@image_ids, $profile_image_id);

    my $user_id = $User->{'id'};

    ##### Get Private Messages
    
    my $PrivateMessages = WorldOfAnime::Controller::DAO_Messages::GetMessagesFromUser( $c, $user_id, $from_user_id );

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{messages}  = $PrivateMessages;
    $c->stash->{from_user} = $FromUser;
    $c->stash->{template}  = 'messages/view_private_messages_from_user.tt2';	
}


sub view_private_messages_to_user :Path('/pm/to') :Args(1) {
    my ( $self, $c, $to_user_id ) = @_;
    my @image_ids;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your private messages.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $User = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $ToUser = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $to_user_id );

    push (@image_ids, $User->{'background_profile_image_id'});

    ##### Get Private Messages

    
    my $PrivateMessages = WorldOfAnime::Controller::DAO_Messages::GetMessagesToUser( $c, $user_id, $to_user_id );

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{messages}  = $PrivateMessages;
    $c->stash->{to_user} = $ToUser;
    $c->stash->{template}  = 'messages/view_private_messages_to_user.tt2';	
}



sub setup_pm_box :Path('/pm/setup') :Args(1) {
    my ( $self, $c, $to_id ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to send a private message.");
    
    my $from_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $to_id );
    
    my $p = $c->model('Users::UserProfile');
    $p->get_profile_image( $c, $to_id );
    my $profile_image_id = $p->profile_image_id;
    
    my $i = $c->model('Images::Image');
    $i->build($c, $profile_image_id);
    my $profile_image_url = $i->thumb_url;    
    
    my $friend_status = WorldOfAnime::Controller::DAO_Friends::GetFriendStatus( $c, $from_id, $to_id);    

    unless ($friend_status == 2) {
	$c->stash->{error_message} = "I don't think you guys are friends.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }

    # Do we have an orig text to get?
    
    my $reply_subject;
    my $reply_text;
    my $orig = $c->req->params->{'orig'};
    
    if ($orig) {
	# Get text
	
	my $PM = $c->model('Messages::PrivateMessage');
	$PM->build( $c, $orig );

	# You can only see messages you've either written, or that are yours
	if (( $from_id == $PM->user_id) || ($from_id == $PM->from_user_id) ) {
	    $reply_subject = $PM->subject;
	    #$reply_text   = $PM->message;
	}

	$c->stash->{orig} = $orig;
    }
    
    $c->stash->{user} = $u;
    $c->stash->{profile_image_url} = $profile_image_url;
    $c->stash->{reply_subject} = $reply_subject;
    $c->stash->{reply_text} = $reply_text;
    $c->stash->{template} = 'messages/pm_box.tt2';
    $c->forward('View::Plain');
}


sub send_private_message :Path('/pm/send_private_message') :Args(1) {
    my ( $self, $c, $to_id ) = @_;
    my $body;
    my $Email;

    my $UserID = $to_id;
    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, $to_id );
    my $ToUsername = $User->username;
    
    my $pm_subject = $c->req->param('subject');
    my $message    = $c->req->param('message');
    my $orig       = $c->req->param('orig') || 0;
    my $sender_id  = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Who is this from?

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $sender_id );
    my $FromUsername = $u->{'username'};   

    # One quick check here to make sure this person really is your friend (to prevent sneaky people from manipulating the URLs)

    my $friend_status = WorldOfAnime::Controller::DAO_Friends::GetFriendStatus( $c, $sender_id, $UserID);

    unless ($friend_status == 2) {
	$c->stash->{error_message} = "I don't think you guys are friends.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }

    if ($orig) {
	my $parent = $orig;
	
	# Also, if there is an orig value, make sure the original is either this person, or the replier's PM (also to prevent manipulating the URL)
	# And keep chasing orig up until its parent is 0

	my $PM = $c->model('Messages::PrivateMessage');
	$PM->build( $c, $orig );

	# You can only see messages you've either written, or that are yours
	if (! (( $sender_id == $PM->user_id) || ($sender_id == $PM->from_user_id)) ) {
	    $c->stash->{error_message} = "Trying to reply to a private message that isn't yours?";
	    $c->stash->{template}      = 'error_page.tt2';
	    $c->detach();
	}

	##### Need to implement this
	
	until ($parent == 0) {
	    $orig = $parent;
	    my $PM = $c->model('Messages::PrivateMessage');
	    $PM->build( $c, $orig );
	    $parent = $PM->parent_pm;
	}
	
	
    }
    
    
    
    my $PrivateMessage = $c->model("DB::PrivateMessages")->create({
	parent_pm       => $orig,
        user_id         => $UserID,
        from_user_id    => $sender_id,
	subject         => $pm_subject,
        message         => $message,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    my $pm_id = $PrivateMessage->id;
    
    $c->cache->remove("woa:num_unread_pms:$to_id");
    $c->cache->remove("woa:pm_count:$to_id:$sender_id");
    
    # If this person is new to sending you PMs (meaning you have exactly 1), we need to delete woa:user_messages:$user_id as well

    my $messages;
    my $total;
    
    my $pms = $c->model('Messages::UserMessages');
    $pms->build( $c, $to_id );
    my $messages_json = $pms->model_find_single_user_info( $c, $to_id, $sender_id );
    
    if ($messages_json) { $messages = from_json( $messages_json ); }
    
    foreach my $m (@{ $messages}) {
        $total += $m->{num_read};
        $total += $m->{num_unread};
    }
    
    if ($total == 1) {
        $c->cache->remove("woa:user_messages:$to_id");
    }    
    
    
    
    #####
    
    if ($orig) {
	# If this has a parent_pm, then it is part of a thread and the memcached key must be erased
	$c->cache->remove("woa:pm_thread:$orig");
    }
    
    # Do they want to know about it?
		
    if ($User->user_profiles->notify_private_message) {

	my $subject = "New Private Message.";
	$body = <<EndOfBody;
You have received a new Private Message from $FromUsername at World of Anime!

To view your Private Messages, just log in to the site and go to http://www.worldofanime.com/pm

if you do not want to receive e-mail notifications when you receive a new Private Message anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody
    
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $body, $subject);


    }
    
    WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "<a href=\"/profile/$FromUsername\">$FromUsername</a> sent you a <a href=\"/pm/$pm_id\">private message</a>", 4);
    
    $c->response->body("sent");
}


sub delete_pm :Path('/pm/delete') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to do this.");
    
    my $user_id    = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $message_id = $c->req->params->{'pm_id'};
    
    my $PM = $c->model('Messages::PrivateMessage');
    $PM->build( $c, $message_id );
    
    ##### Make sure this is really their PM
    unless ($PM->user_id == $user_id ) {
	# Have to die here, this isn't their message
	
	$c->stash->{error_message} = "This doesn't appear to be one of your private messages.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();	
    }
    
    $PM->delete( $c );
    
}


sub mark_user_read :Path('/pm/mark_user_read') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to do this.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $from_user_id = $c->req->params->{'from_user_id'};
    
    my $PMs = $c->model("DB::PrivateMessages")->search({
	-AND => [
	  user_id => $user_id,
	  from_user_id => $from_user_id,
	  is_read => 0
	],
	});
    $PMs->update({ is_read => 1 });
    
    $c->cache->remove("woa:num_unread_pms:$user_id");
    $c->cache->remove("woa:pm_count:$user_id:$from_user_id");    
    
    $c->response->body("done");
}


sub delete_pms :Path('/pm/delete_pms') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to do this.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $from_user_id = $c->req->params->{'from_user_id'};
    my $type         = $c->req->params->{'type'};

    my $PMs;
    
    if ($type eq "all") {
	$PMs = $c->model("DB::PrivateMessages")->search({
	    -AND => [
	      user_id => $user_id,
	      is_deleted => 0,
	    ],
	    });	
    } else {
	$PMs = $c->model("DB::PrivateMessages")->search({
	    -AND => [
	      user_id => $user_id,
	      from_user_id => $from_user_id,
	      is_deleted => 0,
	    ],
	    });
    }
    
    if (defined($PMs)) {

	# Slow way
	while (my $message = $PMs->next) {
	    my $PM = $c->model('Messages::PrivateMessage');
	    $PM->build( $c, $message->id );
	
	    $PM->delete( $c );
	}

    }

    $c->cache->remove("woa:num_unread_pms:$user_id");
    $c->cache->remove("woa:pm_count:$user_id:$from_user_id");    
    
    $c->response->body("done");
}


sub mark_all_read :Path('/pm/mark_all_read') :Args(0) {
        my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to do this.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $PMs = $c->model("DB::PrivateMessages")->search({
	-AND => [
	  user_id => $user_id,
	  is_read => 0,
	],
	});
    $PMs->update({ is_read => 1 });
    
    $c->cache->remove("woa:num_unread_pms:$user_id");

    # For this, we have to go through every user who has sent a message, and clear out their woa:pm_count:$user_id:$from_user_id cache entry
    my $all_users;
    
    my $pms = $c->model('Messages::UserMessages');
    $pms->build( $c, $user_id );
    my $all_users_json = $pms->all_users_received;
    
    if ($all_users_json) { $all_users = from_json( $all_users_json ); }

    foreach my $u (@{ $all_users}) {  # All users that have sent a message
        my $from_user_id  = $u->{user_id};
        $c->cache->remove("woa:pm_count:$user_id:$from_user_id");
    }
    
    $c->response->body("done");
}


__PACKAGE__->meta->make_immutable;

