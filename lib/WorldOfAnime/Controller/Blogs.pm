package WorldOfAnime::Controller::Blogs;
use Moose;
use namespace::autoclean;
use HTML::Restrict;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    my $hr = HTML::Restrict->new();
    
    # Get most recent blog entries
    
    my $cid = "worldofanime:latest_blog_entries";

    my $LatestBlogEntriesHTML = $c->cache->get($cid);;
    
    unless ($LatestBlogEntriesHTML) {
	my $Blogs = $c->model('DB::Blogs')->search({
        },{
            order_by => 'createdate DESC'
          })->slice(0, 9);
    
		
        while (my $blog = $Blogs->next) {
		my $displayPostDate = WorldOfAnime::Controller::Root::PrepareDate($blog->createdate, 1, $tz);

		my $username = $blog->blog_user->username;
		
		my $p = $c->model('Users::UserProfile');
		$p->get_profile_image( $c, $blog->blog_user->id );
		my $profile_image_id = $p->profile_image_id;
		my $height = $p->profile_image_height;
		my $width  = $p->profile_image_width;
		
		my $i = $c->model('Images::Image');
		$i->build($c, $profile_image_id);
		my $profile_image_url = $i->thumb_url;

		my $mult    = ($height / 80);

		my $new_height = int( ($height/$mult) / 1.5 );
		my $new_width  = int( ($width/$mult) /1.5);
				
		my $r_link   = "/blogs/$username/" . $blog->id;
		my $title    = $blog->subject || "No Subject";
		my $description = $hr->process($blog->post);
		$description = substr($description, 0, 250);
		$description .= "...";
		
		$LatestBlogEntriesHTML .= "<div id=\"new_blogs_box\">\n";
		$LatestBlogEntriesHTML .= "<a href=\"$r_link\"><img src=\"$profile_image_url\" height=\"$new_height\" width=\"$new_width\"></a>\n";
		$LatestBlogEntriesHTML .= "<h2><a href=\"$r_link\">$title</a></h2>\n";
	        $LatestBlogEntriesHTML .= "$description";
		$LatestBlogEntriesHTML .= "<p class=\"byline\">Entered by <a href=\"/profile/$username\">$username</a> on $displayPostDate</p>\n";
		$LatestBlogEntriesHTML .= "<br clear=\"all\">\n";
		$LatestBlogEntriesHTML .= "</div>\n";
		
	    }
	
	$c->cache->set($cid, $LatestBlogEntriesHTML);
    }
    
    $c->stash->{latest_blog_entries}  = $LatestBlogEntriesHTML;
    $c->stash->{template} = 'blogs/recent_blogs.tt2';    
}

sub add_blog_entry :Path('/blogs/add_blog_entry') :Args(1) {
    my ( $self, $c, $user ) = @_;
    my $body;
    
    # As a check, make sure this is the real user

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);    
    
    # Try to get a user profile
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID  = $u->{'id'};
    
    unless ($viewer_id == $UserID) {
        # Wait, this isn't the right person!  Don't let them do it!
        
	$c->stash->{error_message} = "Hey, this isn't your blog!";
	$c->stash->{template}    = 'error_page.tt2';
	$c->detach();	
        
    }
    
    my $title = $c->req->params->{'blog_title'};
    my $blog  = $c->req->params->{'blog_post'};
    
    
    my $Blog = $c->model('DB::Blogs')->create({
       user_id => $UserID,
       subject => $title,
       post    => $blog,
       views   => 0,
       modifydate => undef,
       createdate => undef,
    });
    
    my $blog_id = $Blog->id;
    
    my $HTMLUsername = $user;
    $HTMLUsername =~ s/ /%20/g;
    
    
    # Email friends
    my %Emailed;

    my $to_email;
    my $from_email = '<meeko@worldofanime.com> World of Anime';
    my $subject = "$user has posted a new blog entry.";

    $body = <<EndOfBody;
Your friend $user has posted a new blog entry

You can see it at http://www.worldofanime.com/blogs/$HTMLUsername/$blog_id

To stop receiving these notices, log on to your profile at http://www.worldofanime.com/ and change your preference by unchecking "When a friend posts a new blog entry" under Notifications.
EndOfBody
    
    my $friends;
    my $friends_json = WorldOfAnime::Controller::DAO_Friends::GetFriends_JSON( $c, $UserID );
    if ($friends_json) { $friends = from_json( $friends_json ); }

    foreach my $f (@{ $friends}) {
	
	my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $f->{id} );
    
	if ($e->{friend_blog_post}) {

		push (@{ $to_email}, { 'email' => $f->{email} });
		
	$Emailed{$f->{email}} = 1;
	}
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $f->{id}, "<a href=\"/profile/" . $HTMLUsername . "\">" . $HTMLUsername . "</a> has posted a new blog entry titled <a href=\"/blogs/$HTMLUsername/$blog_id\">$title</a>.", 3);
    }
    
    if ($to_email) {
	WorldOfAnime::Controller::DAO_Email::StageEmail($c, $from_email, $subject, $body, to_json($to_email));	    
    }    



    # E-mail everyone who has subscribed to this blog
    undef($to_email);
    $from_email = '<meeko@worldofanime.com> World of Anime';
    $subject = "$user has posted a new blog entry.";    

    my $Body;
	
    $Body .= "$user has posted a new blog entry titled $title\n\n";
    $Body .= "You can see it at http://www.worldofanime.com/blogs/$HTMLUsername/$blog_id\n\n";
    $Body .= "You can also unsubscribe from this blog from the URL above.";
	
    my $Subs = $c->model('DB::BlogUserSubscriptions')->search({
	subscribed_to_user_id => $UserID,
    });
    
    while (my $s = $Subs->next) {
	# Figure out user in s
	my $SubUser = $s->subscriber;

	next if ($Emailed{$SubUser->email});

	push (@{ $to_email}, { 'email' => $SubUser->email });
	
	unless ($SubUser->id == $UserID) {
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $SubUser->id, "<a href=\"/profile/" . $user . "\">" . $user . "</a> has posted a new blog entry titled <a href=\"/blogs/$user/$blog_id\">$title</a>.", 1);
	}
    }
    
    if ($to_email) {
	WorldOfAnime::Controller::DAO_Email::StageEmail($c, $from_email, $subject, $Body, to_json($to_email));	    
    }
    


    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $user . "\">" . $user . "</a> posted a new ";
    $ActionDescription   .= "<a href=\"/blogs/" . $user . "/" . $Blog->id . "\">blog entry</a>";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $UserID, $ActionDescription, 7, $Blog->id);
    
    ### End User Action
    

    # Now, clear out the Newest Blog Entries cache, so this shows up on the homepage
        
    $c->cache->remove("worldofanime:latest_blog_entries");
    $c->cache->remove("worldofanime:latest_blog_entry");
        
    $c->response->redirect("/blogs/$user");    
}



sub edit_blog_entry :Path('/blogs/edit_blog_entry') :Args(1) {
    my ( $self, $c, $id ) = @_;
    
    # Get this blog entry
    
    my $b = WorldOfAnime::Controller::DAO_Blogs::GetCacheableBlogByID( $c, $id);
    my $UserID = $b->{'user_id'};
    my $user   = $b->{'username'};
    
    # As a check, make sure this is the right user

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);    
    
    unless ($viewer_id == $UserID) {
        # Wait, this isn't the right person!  Don't let them do it!
	$c->stash->{error_message} = "This isn't your blog!";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
    my $subject = $c->req->params->{'blog_title'};
    my $post    = $c->req->params->{'blog_post'};
    
    
    my $Blog = WorldOfAnime::Controller::DAO_Blogs::GetBlogByID( $c, $id );
    
    $Blog->update({
	subject => $subject,
	post => $post,
    });

    WorldOfAnime::Controller::DAO_Blogs::BlogCleanup( $c, $id );
        
    $c->response->redirect("/blogs/$user/$id");
}


sub delete_blog :Path('/blogs/delete_blog') :Args(1) {
    my ( $self, $c, $id ) = @_;
    
    # Get this blog entry

    my $Blog = WorldOfAnime::Controller::DAO_Blogs::GetBlogByID( $c, $id );
    my $UserID = $Blog->user_id;
    my $user   = $Blog->blog_user->username;

    # As a check, make sure this is the right user

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);    
    
    unless ($viewer_id == $UserID) {
        # Wait, this isn't the right person!  Don't let them do it!
	$c->stash->{error_message} = "This isn't your blog!";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
    # If they got here, they must really want this sucker gone.

    
    # Delete all comments

    my $BlogComments = $c->model('DB::BlogComments')->search({
        blog_id => $id, 
    });
    
    $BlogComments->delete;
    
    # Delete the real blog
    
    $Blog->delete;
    
    WorldOfAnime::Controller::DAO_Blogs::BlogCleanup( $c, $id );    

    $c->response->redirect("/blogs/$user");  
}



sub view_blog_entries :Path('/blogs') :Args(1) {
    my ( $self, $c, $user ) = @_;

    my $is_self;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);    
    
    # Try to get a user profile
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID = $u->{'id'};
    
    if ( ($viewer_id) && ($viewer_id == $UserID) ) { $is_self = 1; }

    # If the viewer is the owner of this blog, show them the add link
    
    if ($viewer_id == $UserID) {
        $c->stash->{add_blog_link} = "add_blog";
    }    

    # Get all blogs for this user (for now, maybe paginate later when there are lots of them)
    
    my $Blogs = $c->model('DB::Blogs')->search({
        user_id => $UserID,
    },{
        order_by => 'createdate DESC'
      });
    

    my $BlogHTML;
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $HR = "<hr style=\"width: 90%; color: #E01BA5; height: 1px;\">\n";

    while (my $blog = $Blogs->next) {
	my $post_date = $blog->createdate;
	my $displayPostDate = WorldOfAnime::Controller::Root::PrepareDate($post_date, 1, $tz);

        $BlogHTML .= "<div id=\"blog_entry\">\n";

        # Get Blog Comments
    
        my $BlogComments = $c->model('DB::BlogComments')->search({
           blog_id => $blog->id, 
        });
    
        my $num_comments = $BlogComments->count;
	
	my $blog_post  = WorldOfAnime::Controller::Root::ResizeComment($blog->post, 540);

        $BlogHTML .= "<span class=\"comment_byline\"><img src=\"/static/images/comment.gif\"> <a href=\"/blogs/$user/" . $blog->id . "#comments\">$num_comments Comments</a></span>\n";
        $BlogHTML .= "<span class=\"blog_subject\"><a href=\"/blogs/$user/" . $blog->id . "\">" . $blog->subject . "</a></span>\n";
        $BlogHTML .= "<span class=\"blog_post\">" . $blog_post . "</span>\n";
        $BlogHTML .= "<span class=\"blog_byline\">Posted " . $displayPostDate . "</span>\n";
        $BlogHTML .= "</div>\n";
	
	$BlogHTML .= $HR;
    }

    if ($BlogHTML) { $BlogHTML =~ s/$HR$//; }
    
    $c->stash->{blog_html}    = $BlogHTML;
    $c->stash->{is_self}      = $is_self;
    $c->stash->{username}     = $user;
    $c->stash->{user}         = $u;
    $c->stash->{template}     = 'blogs/view_all_blogs.tt2';
}


### Delete a comment

sub delete_comment :Path('/blogs/comment/delete') :Args(0) {
    my ( $self, $c ) = @_;

    my $id = $c->req->param('comment');
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Try to delete the comment of id $id and user_id = $UserID

    my $Comment = $c->model("DB::BlogComments")->search({
	id             => $id,
        user_id        => $UserID,
    });
    
    $Comment->delete; 
}


sub view_blog :Path('/blogs') :Args(2) {
    my ( $self, $c, $user, $blog_id ) = @_;
    my $Sub;
    my $blog; # Individual blog entry

    my $is_self;
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    # Try to get a user profile

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID   = $u->{'id'};

    if ($viewer_id == $UserID) { $is_self = 1; }

    # If the viewer is the owner of this blog, show them the add link
    
    if ($viewer_id == $UserID) {
        $c->stash->{add_blog_link} = "add_blog";
    }
    
    # Have you blocked this user?
    my $IsBlock = WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $UserID, $viewer_id );
    if ($IsBlock) { $c->stash->{is_blocked} = 1; }  
        
    # Get this blog entry
    
    my $Blog = WorldOfAnime::Controller::DAO_Blogs::GetCacheableBlogByID( $c, $blog_id);
    
    unless ($Blog->{'id'}) {
        # Wait, this isn't the right person!  Don't let them do it!
	$c->stash->{error_message} = "I can't seem to find this blog entry.  Maybe it was deleted?";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }    

    # Update count (unless me)
    
    #unless ($viewer_id == 3) {
        #$blog->update({
            #views => $blog->views + 1,
        #});
    #}

    # Get Blog Comments
    
    my $BlogComments = $c->model('DB::BlogComments')->search({
       blog_id => $blog_id, 
    });
    
    my $num_comments = $BlogComments->count;

    my $BlogCommentsHTML;
    
    $BlogCommentsHTML .= "<div id=\"posts\">\n";
    
    while (my $comment = $BlogComments->next) {

	my $comment_id    = $comment->id;
        my $blog_comment  = WorldOfAnime::Controller::Root::ResizeComment($comment->comment, 540);
	$blog_comment     = WorldOfAnime::Controller::Root::CleanComment($blog_comment);
        my $username      = $comment->blog_commentor->username;

	my $p = $c->model('Users::UserProfile');
	$p->get_profile_image( $c, $comment->user_id );
	my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
	
	my $i = $c->model('Images::Image');
	$i->build($c, $profile_image_id);
	my $profile_image_url = $i->thumb_url;	

        my $date          = $comment->createdate;
	my $displayDate = WorldOfAnime::Controller::Root::PrepareDate($date, 1, $tz);
        
        $blog_comment =~ s/\n/<br \/>/g;
        
        $BlogCommentsHTML .= "<div id=\"individual_post\" class=\"comment_" . $comment_id . "\">\n";
	if ($is_self) {
	    $BlogCommentsHTML .= "<a href=\"#\" class=\"delete-comment\" id=\"" . $comment_id . "\"><div id=\"delete_button\">delete</div></a>\n";
	}	
        $BlogCommentsHTML .= "<table>\n";
        $BlogCommentsHTML .= "<tr>\n";
        $BlogCommentsHTML .= "<td valign=\"top\"><a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a></td>\n";
        $BlogCommentsHTML .= "<td valign=\"top\"><span class=\"post\">$blog_comment</span></td>\n";
        $BlogCommentsHTML .= "</tr>\n";
        $BlogCommentsHTML .= "</table>\n";
        $BlogCommentsHTML .= "<span class=\"post_byline\">Posted by $username on $displayDate</span>\n";
        $BlogCommentsHTML .= "</div>\n";

    }
    
    $BlogCommentsHTML .= "</div>\n";


    if ($viewer_id) {
	# Someone is logged in - lets see if they are subscribed to this blog
	
	$Sub = $c->model('DB::BlogSubscriptions')->find({
	    blog_id => $blog,
	    user_id   => $viewer_id,
	});
	
	if ($Sub) {
	    $c->stash->{IsSub} = 1;
	}
    }
    
    $c->stash->{blog}        = $Blog;
    $c->stash->{blog_comments} = $BlogCommentsHTML;
    $c->stash->{num_comments} = $num_comments;
    $c->stash->{user}        = $u;
    $c->stash->{is_self}     = $is_self;
    $c->stash->{template} = 'blogs/view_blog_entry.tt2';    
}


sub blog_branch3 :Path('/blogs') :Args(3) {
    my ( $self, $c, $user, $blog, $action ) = @_;

    if ($action eq "add_comment") {
        $c->forward('add_comment');
    }
    
    if ($action eq "subscribe") {
	$c->forward('subscribe_blog');
    }

    if ($action eq "unsubscribe") {
	$c->forward('unsubscribe_blog');
    }

    if ($action eq "subscribe_blog") {
	$c->forward('subscribe_blog_user');
    }

    if ($action eq "unsubscribe_blog") {
	$c->forward('unsubscribe_blog_user');
    }
    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();    
}


sub check_blog_subscription :Path('/blogs/check_subscription') :Args(4) {
    my ( $self, $c, $username, $user, $subscriber, $source ) = @_;
    my $HTML;
    
    # Check for subscription
    
    my $Sub = $c->model('DB::BlogUserSubscriptions')->find({
	subscriber_user_id => $subscriber,
	subscribed_to_user_id => $user,
    });
    
    if ($Sub) {
	$HTML .= "<span class=\"sub_yes\">You are subscribed to this blog.</span><br />\n";
	$HTML .= "<a href=\"/blogs/$username/$source/unsubscribe_blog\">Unsubscribe</a>\n";
    } else {
	$HTML .= "<span class=\"sub_no\">You are not subscribed to this blog.</span><br />\n";
	$HTML .= "<a href=\"/blogs/$username/$source/subscribe_blog\">Subscribe</a>\n";
    }
    
    $c->response->body($HTML);
}


sub add_comment :Local {
    my ( $self, $c, $user, $blog_id_num, $action ) = @_;
    my $blog; # Individual blog entry
    my $body;
    my $Email;

    my $User = $c->model("DB::Users")->find({
        username => $user
    });
    
    # Get this blog entry
    
    my $Blog = $c->model('DB::Blogs')->search({
        id      => $blog_id_num,
    });
    
    $blog = $Blog->first;

    # If there is not a logged in user, go back to the originating blog page    
    my $commentor_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    unless ($commentor_id) {
	$c->response->redirect("/blogs/$user/$blog_id_num"); 
    }
    
    my $comment      = $c->req->params->{'comment'};
 
    # Who is this from?
		
    my $From = $c->model("DB::Users")->find({
    	id => $commentor_id
    });
    
    my $FromUsername = $From->username;
    
    # Make sure they are on the right person's blog
    
    if (!($user eq $blog->blog_user->username)) {
	$c->stash->{error_message} = "Huh?  Somehow this isn't the right users blog.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
    
    # Have you blocked this user?
    if ( WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $blog->user_id, $commentor_id )) {
	$c->stash->{error_message} = "This user has blocked you from posting on their blog.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
        
    
    my $Comment = $c->model("DB::BlogComments")->create({
        blog_id         => $blog->id,
        user_id         => $commentor_id,
        comment         => $comment,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    my $HTMLUsername = $user;
    $HTMLUsername =~ s/ /%20/g;


    # Do they want to know about it?
    
    my $blog_title   = $blog->subject;
    my $blog_id      = $blog->id;
    my $blog_user_id = $blog->user_id;
		
    if ($User->user_profiles->notify_blog_comment) {

    $body = <<EndOfBody;
You have received a new comment on your Blog Entry entitled $blog_title at World of Anime!

To view your new comment, just go to http://www.worldofanime.com/blogs/$HTMLUsername/$blog_id

if you do not want to receive e-mail notifications when you receive a new blog comment anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody

    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $body, 'New Blog Comment');
		
		}

    WorldOfAnime::Controller::Notifications::AddNotification($c, $User->id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has commented on your blog entry <a href=\"/blogs/$HTMLUsername/$blog_id\">$blog_title</a>.", 1);


    # E-mail everyone who has subscribed to this blog
    
    my $Subs = $c->model('DB::BlogUserSubscriptions')->search({
	subscribed_to_user_id => $blog_user_id,
    });
    
    while (my $s = $Subs->next) {
	# Figure out user in s
	my $SubUser = $s->subscriber;
	my $name = $user . "'s";
	
	# Create e-mail object
	
	my $Body;
	
	$Body .= "$FromUsername has posted a comment on " . $user . "'s blog post titled $blog_title\n\n";
	$Body .= "Read the blog entry here - http://www.worldofanime.com/blogs/$user/$blog_id\n\n";
	$Body .= "You can also unsubscribe from this blog from the URL above.";

	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $SubUser->email, 1, $Body, 'New Blog Comment');
	
	unless ($SubUser->id == $User->id) {
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $SubUser->id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has commented on <a href=\"/profile/$user\">$name</a> blog entry <a href=\"/blogs/$user/$blog_id\">$blog_title</a>.", 1);
	}
    }
    
    
    
    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> posted a comment on ";
    $ActionDescription   .= "<a href=\"/blogs/" . $user . "/" . $blog->id . "\">" . $user . "'s Blog</a>";

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $From->id,
	action_id => 8,
	action_object => $blog->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    ### End User Action
    
    
    $c->response->redirect("/blogs/$user/$blog_id");  
}


### Keep this one!
sub subscribe_blog_user :Local {
    my ( $self, $c, $user, $source ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # If no viewer_id (not a logged in user), get out of here!
    unless ($viewer_id) {
	$c->stash->{error_message} = "Doesn't look like you're logged in.  Log in before subscribing to this user's blog.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
    # Get this user
    
    my $User = $c->model('DB::Users')->find({
        username      => $user,
    });
    
    my $user_id    = $User->id;
    
    # Get subscriber
    
    my $Subscriber = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $Subscriber->username;

    
    # Add subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::BlogUserSubscriptions')->create({
	    subscriber_user_id => $viewer_id,
	    subscribed_to_user_id => $user_id,
	    modify_date => undef,
	    create_date => undef,
        });
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has subscribed to your blog.", 8);
    }

    if ($source == 0) {
	$c->response->redirect("/blogs/$user");
    } else {
	$c->response->redirect("/blogs/$user/$source")
    }
}



### Keep this one!
sub unsubscribe_blog_user :Local {
    my ( $self, $c, $user, $source ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # If no viewer_id (not a logged in user), get out of here!
    unless ($viewer_id) {
	$c->stash->{error_message} = "Doesn't look like you're logged in.  Log in before unsubscribing from this user's blog.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
    # Get this user
    
    my $User = $c->model('DB::Users')->find({
        username      => $user,
    });
    
    my $user_id    = $User->id;
    
    # Get subscriber
    
    my $Subscriber = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $Subscriber->username;

    
    # Remove subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::BlogUserSubscriptions')->find({
	    subscriber_user_id => $viewer_id,
	    subscribed_to_user_id => $user_id,
        });
	
	if ($Sub) {
	    $Sub->delete;
	    
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has unsubscribed from your blog.", 13);
	}
    }

    if ($source == 0) {
	$c->response->redirect("/blogs/$user");
    } else {
	$c->response->redirect("/blogs/$user/$source")
    }
}



__PACKAGE__->meta->make_immutable;

