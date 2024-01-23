package WorldOfAnime::Controller::Forums;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use List::MoreUtils qw(uniq);



sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $ForumHTML;

    # This is the main forum display
    
    # Get all categories - old style
    
    my $OldCategories = $c->model('DB::ForumCategories')->search({ }, {
        order_by => 'display_order',
        });

    $c->stash->{images_approved} = 1;
    $c->stash->{categories} = $OldCategories;
    $c->stash->{template}   = 'forums/main.tt2';
}


sub ajax_load_post_editable :Path('/forums/ajax/load_post_editable') :Args(1) {
    my ( $self, $c, $id ) = @_;
    my $post;
    
    my $Post = WorldOfAnime::Controller::DAO_Forums::FetchPostByID( $c, $id );
    
    # Make sure this is the right person
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $userid    = $Post->user_id->id;
    
    unless ($viewer_id == $userid) {
	$c->response->body("This isn't your post, or you are not logged in.");
    } else {
    
	$post  = "<form id=\"submit_edit\">\n";
	$post .= "<input type=\"hidden\" name=\"post_id\" value=\"$id\">\n";
	$post .= "<textarea name=\"post\" id=\"post\" rows=\"12\">";
	$post .= $Post->post;
	$post .= "</textarea>\n";
	$post .= "<input type=\"Submit\" value=\"Edit Post\">\n";
	$post .= "</form>\n";
    
	$c->response->body($post);
    }
}


sub ajax_edit_post :Path('/forums/ajax/edit_post') :Args(1) {
    my ( $self, $c, $id ) = @_;
    my $NewPost = $c->req->params->{post};
    
    my $Post = WorldOfAnime::Controller::DAO_Forums::FetchPostByID( $c, $id );
    
    # Make sure this is the right person
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $userid    = $Post->user_id->id;
    
    unless ($viewer_id == $userid) {

    } else {

	$Post->update({ post => $NewPost });

    }    
}


sub ajax_load_post :Path('/forums/ajax/load_post') :Args(1) {
    my ( $self, $c, $id ) = @_;
    my $post;
    
    $post = WorldOfAnime::Controller::DAO_Forums::FetchForumPostForDisplay( $c, $id );

    $c->response->body($post);
}


sub ajax_load_post_content :Path('/forums/ajax/load_post_content') :Args(1) {
    my ( $self, $c, $id ) = @_;
    my $post;
    my $name = $c->req->params->{'name'} || "An unknown person";
    
    my $originalPost = WorldOfAnime::Controller::DAO_Forums::FetchForumPostContent( $c, $id );
    my $cleanPost    = WorldOfAnime::Controller::DAO_Format::CleanBBCode( $originalPost );
    $cleanPost =~ s/^\n//;
    $cleanPost =~ s/\n$//;
    
    $post  = "[QUOTE=\"$name\"]";
    $post .= $cleanPost;
    $post .= "[/QUOTE]\n";

    $c->response->body($post);
}


sub show_forum :Path('/forums') :Args(2) {
    my ( $self, $c, $category, $forum ) = @_;

    # This shows the threads for the forum

    my $page = $c->req->params->{'page'} || 1;
    
    # First, figure out the forum ID based on the URL
    
    # Translate old category names into new ones
    $category =~ s/welcome_center/general/;
    
    my $Forum = $c->model('DB::ForumForums')->find({
        'me.pretty_url' => "$forum",
        'category_id.pretty_url' => "$category"
    },{
       join => [ 'category_id' ],
      '+select' => [ 'me.id' ],
      '+as'     => [ 'id' ],
    });
    
    my $ForumID = $Forum->id;
    
    my $Threads = $c->model('DB::ForumThreads')->search({
        forum_id => "$ForumID"
    },{
      page      => "$page",
      rows      => 30,        
      order_by  => 'last_post DESC'
      });

    my $pager = $Threads->pager();

    $c->stash->{pager}    = $pager;        

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff

    $c->stash->{images_approved} = 1;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{threads} = $Threads;
    $c->stash->{forum_name} = $Forum->forum_name;
    $c->stash->{category}   = $Forum->category_id->category_name;
    $c->stash->{forum}      = $forum;
    $c->stash->{template} = 'forums/threads.tt2';    
}





sub branch :Path('/forums') :Args(3) {
    my ( $self, $c, $category, $forum, $action ) = @_;
    
    # New Thread
    
    if ($action eq "new_thread") {
        $c->forward('new_thread');
    }

    if ($action eq "new_thread_preview") {
        $c->forward('new_thread_preview');
    }
    
    if ($action eq "new_thread_add") {
        $c->forward('new_thread_add');
    }
    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();
}


sub view_thread :Path('/forums/thread') :Args(1) {
    my ( $self, $c, $thread ) = @_;
    my $Sub;
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    my $page = $c->req->params->{'page'} || 1;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Verify this is a good thread
    
    if (!WorldOfAnime::Controller::DAO_Forums::IsValidThread($c, $thread)) {
	$c->stash->{error_message} = "Doesn't look like that's a valid thread.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }

    # Get first post, for meta description
    my $description = WorldOfAnime::Controller::DAO_Forums::FetchFirstPostByThread($c, $thread);

    # Get Posts

    my $PostsHTML;

    my $Posts = $c->model('DB::ThreadPosts')->search({
        thread_id => $thread
        },
    {
        page      => "$page",
        rows      => 15,
    });
    
    my $pager = $Posts->pager();

    $c->stash->{pager}    = $pager;    
    
    my $PostCounter = ($page * 15) - 15;
    
		while (my $post = $Posts->next) {
			$PostCounter++;
			
			my $postid        = $post->id;
			my $userid        = $post->user_id->id;
			my $username      = $post->user_id->username;

			my $p = $c->model('Users::UserProfile');
			$p->get_profile_image( $c, $userid );
			my $profile_image_id = $p->profile_image_id;
			
			my $i = $c->model('Images::Image');
			$i->build($c, $profile_image_id);
			my $profile_image_url = $i->thumb_url;

			my $user_post     = $post->post;
			my $date          = $post->create_date;
			my $join_date     = $post->user_id->confirmdate;
			my $displayDate = WorldOfAnime::Controller::Root::PrepareDate($date, 5, $tz);
			my $displayJoinDate = WorldOfAnime::Controller::Root::PrepareDate($join_date, 6, $tz);
			my $displaySubject  = $post->thread_id->subject;
			my $num_forum_posts = WorldOfAnime::Controller::DAO_Forums::FetchNumPosts($c, $post->user_id->id);
			
			unless ($PostCounter == 1) {
			    $displaySubject = "Re: " . $displaySubject;
			}
			
			$user_post  = WorldOfAnime::Controller::DAO_Format::ParseBBCode($user_post);
			
			$PostsHTML .= "<div class=\"individual_post\" id=\"post_$postid\">\n";
			$PostsHTML .= "<table width=\"100%\" cellpadding=\"2px\">\n";
			$PostsHTML .= "<tr>\n";
			$PostsHTML .= " <td class=\"forum_header\" colspan=\"2\">Posted by $username on $displayDate</td>\n";
			$PostsHTML .= "</tr>\n";
			$PostsHTML .= "<tr>\n";
			$PostsHTML .= "	<td width=\"20%\" valign=\"top\"><div id=\"post_profile_image\">\n";

			$PostsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a><p />";
			$PostsHTML .= "<span class=\"forum_info\">Joined: " . $displayJoinDate . "</span><br />\n";
			$PostsHTML .= "<span class=\"forum_info\">Posts: " . $num_forum_posts . "</span><br />\n";
		        $PostsHTML .= "</td>\n";
			$PostsHTML .= "<td width=\"80%\" valign=\"top\" style=\"background: #FCFCF7; border-left: 1px solid #D1DEDD;\">";
			
			$PostsHTML .= "<span class=\"forum_title\">" . $displaySubject . "</span>\n";
			$PostsHTML .= "<span class=\"forum_post\">$user_post</span>";
			
			if ($post->user_id->user_profiles->signature) {
			    my $signature  = WorldOfAnime::Controller::Root::ResizeComment($post->user_id->user_profiles->signature, 480);
			    $PostsHTML .= "<p style=\"border-top: 1px solid #D1DEDD; margin-top: 20px;\">$signature</p>\n";
			}
			
			$PostsHTML .= "</td>\n";
			
			$PostsHTML .= "<tr>\n";
			$PostsHTML .= " <td class=\"forum_footer\" colspan=\"2\">";
			if ($viewer_id) {
			    $PostsHTML .= "<a href=\"#\" class=\"reply_thread\">Reply</a>\n";
			    $PostsHTML .= " . <a href=\"#\" class=\"reply_thread_quote\" id=\"$postid\" user=\"$username\">Reply with Quote</a>\n";
			}
			if ($viewer_id == $userid) {
			    $PostsHTML .= " . <a href=\"#\" class=\"edit_post\" id=\"$postid\">Edit</a>\n";
			}
			
			$PostsHTML .= "</td>\n";
			$PostsHTML .= "</tr>\n";

			$PostsHTML .= "</table>\n";
			$PostsHTML .= "</div>\n";
		}
    
    
    if ($viewer_id) {
	# Someone is logged in - lets see if they are subscribed to this thread
	
	$Sub = $c->model('DB::ForumThreadSubscriptions')->find({
	    forum_thread_id => $thread,
	    user_id   => $viewer_id,
	});
	
	if ($Sub) {
	    $c->stash->{IsSub} = 1;
	}
    }
    
    # Increment this threads Views by 1, if on page 1

    my $Thread = $c->model('DB::ForumThreads')->find({
       id => $thread 
    });

    if ($page == 1) {        
        $Thread->update({
            views => $Thread->views + 1
        });
    }
    

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    $c->stash->{description} = $description;
    $c->stash->{thread}   = $Thread;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{posts_html}    = $PostsHTML;    
    $c->stash->{template} = 'forums/view_thread.tt2';
}


sub subscribe_thread :Local {
    my ( $self, $c, $thread, $action ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Get this thread
    
    my $Thread = $c->model('DB::ForumThreads')->find({
        id      => $thread,
    });
    
    my $user_id = $Thread->started_by_user_id->id;
    my $subject = $Thread->subject;
    
    
    # Get subscriber
    
    my $User = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $User->username;
    
    # Add subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::ForumThreadSubscriptions')->create({
	    forum_thread_id => $thread,
	    user_id => $viewer_id,
	    modify_date => undef,
	    create_date => undef,
        });
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has subscribed to your forum thread <a href=\"/forums/thread/$thread\">$subject</a>.", 8);
    }
    
    $c->response->redirect("/forums/thread/$thread");    
}


sub unsubscribe_thread :Local {
    my ( $self, $c, $thread, $action ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Get this thread
    
    my $Thread = $c->model('DB::ForumThreads')->find({
        id      => $thread,
    });
    
    my $user_id = $Thread->started_by_user_id->id;
    my $subject = $Thread->subject;
    
    
    # Get subscriber
    
    my $User = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $User->username;
    
    # Remove subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::ForumThreadSubscriptions')->find({
	    forum_thread_id => $thread,
	    user_id => $viewer_id,
        });
	
	if ($Sub) {
	    $Sub->delete;
	    
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has unsubscribed from your forum thread <a href=\"/forums/thread/$thread\">$subject</a>.", 13);
	}
    }
    
    $c->response->redirect("/forums/thread/$thread");    
}


sub post_branch :Path('/forums/thread') :Args(2) {
    my ( $self, $c, $thread, $action ) = @_;
    
    if ($action eq "add_post") {
        $c->forward('add_post');
    }
    
    if ($action eq "subscribe") {
	$c->forward('subscribe_thread');
    }

    if ($action eq "unsubscribe") {
	$c->forward('unsubscribe_thread');
    }
    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();    
}


sub add_post :Local {
    my ( $self, $c, $thread, $action ) = @_;
    
    my $post     = $c->req->params->{post};
    my $user_id  = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # First, make the post
    
    my $Post = $c->model('DB::ThreadPosts')->create({
        thread_id         => $thread,
        user_id           => $user_id,
        post              => $post,
        modify_date       => undef,
        create_date       => undef,
    });


    # Now, we want to update the last_post field on the Thread
    # Also, subtract 1 from the Views, because we going to add 1 when we forward back
    # Yes, I know this sucks.  Figure out a better way to do it later

    my $Thread = $c->model('DB::ForumThreads')->find({
       id => $thread 
    });
    
    $Thread->update({
        views => $Thread->views - 1,
        last_post => undef
    });
    
    my $ForumID = $Thread->forum_id->id;
    
    
    # Now, we want to find everyone who is subscribed, and send them an e-mail
    
    my $HTMLUsername = $Post->user_id->username;
    $HTMLUsername =~ s/ /%20/g;
    
    my $Subs = $c->model('DB::ForumThreadSubscriptions')->search({
	forum_thread_id => $thread,
    });
    
    while (my $s = $Subs->next) {
	# Figure out user in s
	my $User = $s->subscription_user_id;
	
	# Create e-mail object
	
	my $Body;
	
	$Body .= "http://www.worldofanime.com/profile/$HTMLUsername has replied to the thread titled " . $Thread->subject . " with the following:\n";
	$Body .= $post . "\n";
	$Body .= "Read the full thread here - http://www.worldofanime.com/forums/thread/$thread\n";
	$Body .= "You can also unsubscribe from this thread from the URL above.";

	my $subject = $Thread->subject;
	
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $Body, 'New Thread Post');
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $User->id, "<a href=\"/profile/" . $HTMLUsername . "\">" . $Post->user_id->username . "</a> has replied to the thread <a href=\"/forums/thread/$thread\">$subject</a>.", 1);
    }
    

    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $Post->user_id->username . "\">" . $Post->user_id->username . "</a> posted a ";
    $ActionDescription   .= "<a href=\"/forums/thread/" . $thread . "\">new comment</a> in the forums";

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Post->user_id->id,
	action_id => 5,
	action_object => $thread,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    ### End User Action
    
    
    WorldOfAnime::Controller::DAO_Forums::PostCleanup($c, $user_id, $thread, $ForumID);
    
    $c->response->redirect("/forums/thread/$thread");    
}




sub new_thread :Local {
    my ( $self, $c, $category, $forum ) = @_;
    

    $c->stash->{forum_name} = $forum;
    $c->stash->{subject} = $c->req->params->{subject};
    $c->stash->{thread} = $c->req->params->{thread};    
    $c->stash->{template} = 'forums/new_thread.tt2';
}


sub new_thread_preview :Local {
    my ( $self, $c, $category, $forum ) = @_;

    my $display_thread = $c->req->params->{thread};
    $display_thread =~ s/\n/<br \/>/g;

    $c->stash->{subject} = $c->req->params->{subject};
    $c->stash->{thread} = $c->req->params->{thread};
    $c->stash->{display_thread} = $display_thread;
    $c->stash->{preview} = 1;
    $c->stash->{template} = 'forums/new_thread.tt2';
}


sub new_thread_add :Local {
    my ( $self, $c, $category, $forum ) = @_;
 
    unless ($c->user_exists() ) {
        $c->stash->{error_message} = "You must be logged in to add a new thread.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }

    # First, figure out the forum ID based on the URL
    
    my $Forum = $c->model('DB::ForumForums')->find({
        'me.pretty_url' => "$forum",
        'category_id.pretty_url' => "$category"
    },{
       join => [ 'category_id' ],
      '+select' => [ 'me.id' ],
      '+as'     => [ 'id' ]
    });
    
    my $ForumID = $Forum->id;
    
    my $subject  = $c->req->params->{subject};
    my $post     = $c->req->params->{thread};
    my $subscribe = $c->req->params->{subscribe};
    my $forum_id = $ForumID;
    my $user_id  = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Create the new thread
    
    my $Thread = $c->model('DB::ForumThreads')->create({
            forum_id           => $forum_id,
            started_by_user_id => $user_id,
            subject            => $subject,
            views              => 0,
            last_post          => undef,
            modify_date        => undef,
            create_date        => undef,
        });


    # Always subscribe me
    
    my $Sub = $c->model('DB::ForumThreadSubscriptions')->create({
        forum_thread_id => $Thread->id,
        user_id => 3,
        modify_date => undef,
        create_date => undef,
    });
		

    # If the poster wants to subscribe, then do them
    
    if ($subscribe) {
	my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
	# Add subscription
    
	   if ($viewer_id) {
	        my $Sub = $c->model('DB::ForumThreadSubscriptions')->create({
	        forum_thread_id => $Thread->id,
	        user_id => $viewer_id,
	        modify_date => undef,
	        create_date => undef,
	    });
	}
    }

    # Create the first post of the new thread
    
    my $Post = $c->model('DB::ThreadPosts')->create({
        thread_id         => $Thread->id,
        user_id           => $user_id,
        post              => $post,
        modify_date       => undef,
        create_date       => undef,
    });
    
    my $HTMLUsername = $Post->user_id->username;
    $HTMLUsername =~ s/ /%20/g;    
    
    ### Create User Action
    
    my $thread_id = $Thread->id;
    
    my $ActionDescription = "<a href=\"/profile/" . $Post->user_id->username . "\">" . $Post->user_id->username . "</a> created a ";
    $ActionDescription   .= "<a href=\"/forums/thread/" . $Thread->id . "\">new thread</a> in the forums";
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Post->user_id->id,
	action_id => 4,
	action_object => $Thread->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    ### End User Action
    
    my $Friends = $c->model("DB::UserFriends")->search({
        user_id => $Post->user_id->id,
        status  => 2,
    },{
                select   => [qw/friend_user_id modifydate/],
                distinct => 1,
		order_by => 'modifydate DESC',
    });
    
    while (my $f = $Friends->next) {
	WorldOfAnime::Controller::Notifications::AddNotification($c, $f->friends->id, "<a href=\"/profile/" . $HTMLUsername . "\">" . $HTMLUsername . "</a> has posted a new forum thread titled <a href=\"/forums/thread/$thread_id\">$subject</a>.", 12);
    }      
    
    WorldOfAnime::Controller::DAO_Forums::PostCleanup($c, $user_id, $thread_id, $ForumID);
    WorldOfAnime::Controller::DAO_Forums::PostNewThreadCleanup($c, $ForumID);
    
    $c->response->redirect("/forums/$category/$forum");
}




1;
