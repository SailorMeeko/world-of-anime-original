package WorldOfAnime::Controller::Groups;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use JSON;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';


sub index :Path('/groups') :Args(0) {
    my ( $self, $c ) = @_;
    my $GroupsHTML;
    
    my $cpage = $c->req->params->{'cpage'} || 1;
    
    my $Groups = $c->model('DB::Groups')->search({
        is_private => 0,
    },{
       page     => "$cpage",
       rows      => 25,
       order_by => 'createdate DESC',
    });
    
    my $cpager = $Groups->pager();

    while (my $group = $Groups->next) {

        my $g = WorldOfAnime::Controller::DAO_Groups::GetCacheableGroupByID( $c, $group->id );

        my $id          = $g->{'id'};
        my $name        = $g->{'name'};
        my $description = $g->{'description'};
        my $prettyurl   = $g->{'pretty_url'};
        my $num_members = $g->{'num_members'};
	my $create_date = $g->{'create_date'};

	my $profile_image_id = $g->{'profile_image_id'};	
	my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;	

	my $displayCreateDate = WorldOfAnime::Controller::Root::PrepareDate($create_date, 1);
	$description = $c->model('Formatter')->clean_html($description);
        $description =~ s/\n/<br \/>/g;
        
        $GroupsHTML .= "<div class=\"top_user_profile_box\">\n";
	$GroupsHTML .= "<table border=\"0\">\n";
	$GroupsHTML .= "	<tr>\n";
	$GroupsHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
	$GroupsHTML .= "			<a href=\"/groups/$id/$prettyurl\"><img src=\"$profile_image_url\" border=\"0\"></a>";
	$GroupsHTML .= "		</td>\n";
	$GroupsHTML .= "		<td valign=\"top\" width=\"560\">\n";
	$GroupsHTML .= "			<span class=\"group_name_link\"><a href=\"/groups/$id/$prettyurl\">$name</a></span><br />\n";
        $GroupsHTML .= "                        <span class=\"top_user_profile_date\">+$num_members members<p />\n";
        $GroupsHTML .= "                        <span class=\"group_description\">$description</span>\n";
	$GroupsHTML .= "		</td>\n";
	$GroupsHTML .= "	</tr>\n";
	$GroupsHTML .= "	<tr>\n";
	$GroupsHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Created on $displayCreateDate</span></td>\n";
	$GroupsHTML .= "	</tr>\n";
	$GroupsHTML .= "</table>\n";
	$GroupsHTML .= "</div>\n\n";
	$GroupsHTML .= "<p />\n";
    }
    #$GroupsHTML .= "</div>\n";
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff

    $c->stash->{cpager}    = $cpager;
    $c->stash->{GroupsHTML}  = $GroupsHTML;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'groups/main.tt2';
}



sub add_new_group :Local {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a new group.");

    my $group_name = $c->req->params->{'group_name'};
    my $group_desc = $c->req->params->{'description'};
    my $is_private = 0;
    
    if ($c->req->params->{'is_private'}) {
        $is_private = 1;
    }

    my $is_approve = 0;
    my $pretty_url = $c->model('Formatter')->prettify( $group_name );
    
    # If they haven't entered a group name or description, send back
    
    unless ($group_name && $group_desc) {
        $c->stash->{error_message} = "You must enter a group name and description.";
        $c->stash->{group_name}    = $group_name;
        $c->stash->{description}   = $group_desc;
        $c->stash->{template}      = 'groups/main.tt2';
        
        my $current_uri = $c->req->uri;
        $current_uri =~ s/\?(.*)//; # To remove the pager stuff    

        $c->stash->{current_uri} = $current_uri;
        $c->detach();        
    }
    
    # Create the group
    
    my $Group = $c->model('DB::Groups')->create({
        name => $group_name,
        pretty_url  => $pretty_url,
        description => $group_desc,
        is_private  => $is_private,
        is_approve  => $is_approve,
        created_by_user_id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
        profile_image_id => 14,
        modifydate => undef,
        createdate => undef,
    });
    
    my $GroupID = $Group->id;
    
    # Create the first user
    
    my $GroupUser = $c->model('DB::GroupUsers')->create({
        group_id => $GroupID,
        user_id  => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
        is_admin => 1,
        modifydate => undef,
        createdate => undef,
    });
    
    
    # Send notification to let friends know that you've created a new group (if it is not private)
     
    my $User = $c->model('DB::Users')->find({
        id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
    });
    
    my $username = $User->username;

    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;    
    
    unless ($is_private) {
        my $Friends = $c->model("DB::UserFriends")->search({
            user_id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
            status  => 2,
        },{
                    select   => [qw/friend_user_id modifydate/],
                    distinct => 1,
            	order_by => 'modifydate DESC',
        });
    
        while (my $f = $Friends->next) {
            WorldOfAnime::Controller::Notifications::AddNotification($c, $f->friends->id, "<a href=\"/profile/" . $HTMLUsername . "\">" . $HTMLUsername . "</a> has created a new group called <a href=\"/groups/$GroupID/$pretty_url\">$group_name</a>", 19);
        }
    }
    
        ### Create User Action
    
        my $ActionDescription = "<a href=\"/profile/" . $HTMLUsername . "\">" . $username . "</a> has created a <a href=\"/groups/$GroupID/$pretty_url\">New Group</a>";
        
        # If private, don't put the Group info in the description
        
        if ($is_private) {
            $ActionDescription = "<a href=\"/profile/" . $HTMLUsername . "\">" . $username . "</a> has created a New Group";
        }
    
        my $UserAction = $c->model("DB::UserActions")->create({
            user_id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
            action_id => 12,
            action_object => $GroupID,
            description => $ActionDescription,
            modify_date => undef,
            create_date => undef,
        });
    
    ### End User Action    

    
    # Forward to the newly created group
    
    &LogEvent($c, $GroupID, "Group created by $HTMLUsername", 1);
    
   $c->response->redirect("/groups/$GroupID/$pretty_url");
   $c->detach();
    
}


sub view_individual_group_comment :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $fetch_comment_id ) = @_;
    my $MembersHTML;
    my $UserID;
    my $latest_reply;
    my $autoScroll = 1;
    my ($metadescription, $metadate, $metadisplaydate);    

    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }
    
    my $User = $c->model('DB::Users')->find({
        id => $UserID,
    });
    

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });


    unless ($Group) {
        $c->stash->{error_message} = "Something is weird.  That Group doesn't look like they exist.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }

    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );


    ##### Get User Comments
    my $UserCommentsHTML;
    my $UserComments;
    my $comment_owner;
    
    my $comment = $c->model("DB::GroupComments")->find({
            id => $fetch_comment_id,
	});

    if ($comment) {
                                $comment_owner    = $comment->group_id;
	    			my $comment_id    = $comment->id;
				my $username      = $comment->group_commentors->username;

				my $p = $c->model('Users::UserProfile');
				$p->get_profile_image( $c, $comment->group_commentors->id );
				my $profile_image_id = $p->profile_image_id;

				my $i = $c->model('Images::Image');
				$i->build($c, $profile_image_id);
				my $profile_image_url = $i->thumb_url;
				
                                my $user_comment  = WorldOfAnime::Controller::Root::ResizeComment($comment->comment, 370);
	    			my $date          = $comment->createdate;
				my $displayDate    = WorldOfAnime::Controller::Root::PrepareDate($date, 1);

				$user_comment =~ s/\n/<br \/>/g;
                                
                                # Use this to build a unique title and description
                                $metadescription = $comment->comment;
                                $metadisplaydate = $displayDate;

				$UserCommentsHTML .= "<div id=\"individual_post\" class=\"comment_" . $comment_id . "\">\n";
				if ($fetch_comment_id == $comment_id) {
				    $UserCommentsHTML .= "<div id=\"highlighted_post\">";
				    $autoScroll = 0;                                    
				}

				if ($IsAdmin) {
				    $UserCommentsHTML .= "<a href=\"#\" class=\"delete-comment\" id=\"" . $comment_id . "\" group_id=\"" . $GroupID . "\" type=\"comment\"><div id=\"delete_button\">delete</div></a>\n";
				}
                                
				$UserCommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" class=\"comment_image\"></a>";				

				$UserCommentsHTML .= "<span class=\"post\">$user_comment</span>\n";
                                $UserCommentsHTML .= "<br clear=\"all\">\n";
        			$UserCommentsHTML .= "<span class=\"post_byline\">Posted by $username on $displayDate</span>\n";
                                
                                if ($fetch_comment_id == $comment_id) {
				    $UserCommentsHTML .= "</div>\n";
				}

                                if ($comment->group_replies > 0) {
                                    my ($latest, $RepliesHTML) = WorldOfAnime::Controller::DAO_Users::GetGroupCommentReplies($self, $c, $comment->id, $GroupID, $fetch_comment_id );
				    $UserCommentsHTML .= "<p> $RepliesHTML </p>\n";
				    $latest_reply = $latest;
				}
				$UserCommentsHTML .= "<div class=\"replies_" . $comment->id . "\"><p> </p></div>\n"; # Create empty div to pull in replies via Ajax
                                
				if ($IsMember) {
				    $UserCommentsHTML .= "<div id=\"setup_reply_" . $comment_id . "\" style=\"text-align: right;\"><a href=\"#\" class=\"reply_linky\" onclick=\"javascript:\$('#reply_" . $comment_id . "').show();\$('#add_comment #comment_box_" . $comment_id . "').focus();\$('#setup_reply_" . $comment_id . "').hide();return false\">Post a Reply</a></div>\n";
				}                                
                                
				if ($IsMember) {
				    $UserCommentsHTML .= "<div id=\"reply_" . $comment_id . "\" class=\"reply_box\">";
				    $UserCommentsHTML .= "<h2>Post a Reply</h2>\n";
                                    $UserCommentsHTML .= "<form id=\"add_comment\" parent=\"$comment_id\" user=\"$username\" latest=\"$latest_reply\" group=\"$GroupID\">";
				    $UserCommentsHTML .= "<input type=\"hidden\" name=\"parent_comment\" value=\"" . $comment_id . "\">\n";
				    $UserCommentsHTML .= "<textarea id=\"comment_box_" . $comment_id . "\" rows=\"4\" cols=\"44\" name=\"comment_box_" . $comment_id . "\"></textarea>\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "<input type=\"submit\" value=\"Reply\" style=\"float: right; margin-right: 25px; margin-top: 5px; margin-bottom: 5px;\" class=\"removable\">\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "</form>\n";
				    $UserCommentsHTML .= "</div>\n";
				}

                                $UserCommentsHTML .= "<br clear=\"all\">\n";
                                $UserCommentsHTML .= "<a href=\"#top\" class=\"back_to_top_link\"><img src=\"/static/images/icons/backtotop.gif\" border=\"0\" height=\"24\" width=\"24\"> Back to Top</a><p />\n";
				$UserCommentsHTML .= "</div>\n";
    } else {
	$UserCommentsHTML .= "I can't find this comment.";
    }

    # Is this the wrong profile?
    
    unless ($GroupID == $comment_owner) {
	$UserCommentsHTML = "I can't find this comment.";
    }
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff   
    
    $c->stash->{IsOwner}       = $IsOwner;
    $c->stash->{IsAdmin}       = $IsAdmin;
    $c->stash->{IsMember}      = $IsMember;
    $c->stash->{IsJoinRequest} = $IsJoinRequest;
    $c->stash->{IsPrivate}     = $Group->is_private;
    $c->stash->{group}         = $Group;
    $c->stash->{GroupComments} = $UserCommentsHTML;
    $c->stash->{user}           = $User;
    $c->stash->{autoScroll}    = $autoScroll;
    $c->stash->{metadate}    = $metadisplaydate;
    $c->stash->{metadescription} = $metadescription;    
    $c->stash->{template}      = 'groups/individual_comment.tt2';
}


sub view_individual_group_reply :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $fetch_comment_id ) = @_;
    my $MembersHTML;
    my $UserID;
    my $latest_reply;
    my $autoScroll = 1;
    my ($metadescription, $metadate, $metadisplaydate);
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }
    
    my $User = $c->model('DB::Users')->find({
        id => $UserID,
    });
    

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });


    unless ($Group) {
        $c->stash->{error_message} = "Something is weird.  That Group doesn't look like they exist.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }

    # Find out this users status

    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );


    # Since we are given the reply, we must get the parent
    my $parent_comment_id;
    
    my $comment = $c->model("DB::GroupCommentReplies")->find({
            id => $fetch_comment_id,
    });
    
    if ($comment) {
        $parent_comment_id = $comment->parent_comment_id;
        
        # Use this to build a unique title and description
        $metadescription = $comment->comment;
	$metadate          = $comment->createdate;
	$metadisplaydate   = WorldOfAnime::Controller::Root::PrepareDate($metadate, 1, $tz);
    }

    ##### Get User Comments
    my $UserCommentsHTML;
    my $UserComments;
    my $comment_owner;
    
    $comment = $c->model("DB::GroupComments")->find({
            id => $parent_comment_id,
	});

    if ($comment) {
                                $comment_owner    = $comment->group_id;
	    			my $comment_id    = $comment->id;
				my $username      = $comment->group_commentors->username;

				my $p = $c->model('Users::UserProfile');
				$p->get_profile_image( $c, $comment->group_commentors->id );
				my $profile_image_id = $p->profile_image_id;
						
				my $i = $c->model('Images::Image');
				$i->build($c, $profile_image_id);
				my $profile_image_url = $i->thumb_url;	

                                my $user_comment  = WorldOfAnime::Controller::Root::ResizeComment($comment->comment, 370);
	    			my $date          = $comment->createdate;
				my $displayDate    = WorldOfAnime::Controller::Root::PrepareDate($date, 1);
				
				$user_comment =~ s/\n/<br \/>/g;

				$UserCommentsHTML .= "<div id=\"individual_post\" class=\"comment_" . $comment_id . "\">\n";
				if ($IsAdmin) {
				    $UserCommentsHTML .= "<a href=\"#\" class=\"delete-comment\" id=\"" . $comment_id . "\" group_id=\"" . $GroupID . "\" type=\"comment\"><div id=\"delete_button\">delete</div></a>\n";
				}

				$UserCommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" class=\"comment_image\"></a>";				

				$UserCommentsHTML .= "<span class=\"post\">$user_comment</span>\n";
                                $UserCommentsHTML .= "<br clear=\"all\">\n";
        			$UserCommentsHTML .= "<span class=\"post_byline\">Posted by $username on $displayDate</span>\n";

                                if ($comment->group_replies > 0) {
                                    my ($latest, $RepliesHTML) = WorldOfAnime::Controller::DAO_Users::GetGroupCommentReplies($self, $c, $comment->id, $GroupID, $fetch_comment_id );
				    $UserCommentsHTML .= "<p> $RepliesHTML </p>\n";
				    $latest_reply = $latest;
				}
				$UserCommentsHTML .= "<div class=\"replies_" . $comment->id . "\"><p> </p></div>\n"; # Create empty div to pull in replies via Ajax
                                
				if ($IsMember) {
				    $UserCommentsHTML .= "<div id=\"setup_reply_" . $comment_id . "\" style=\"text-align: right;\"><a href=\"#\" class=\"reply_linky\" onclick=\"javascript:\$('#reply_" . $comment_id . "').show();\$('#add_comment #comment_box_" . $comment_id . "').focus();\$('#setup_reply_" . $comment_id . "').hide();return false\">Post a Reply</a></div>\n";
				}
                                
				if ($IsMember) {
				    $UserCommentsHTML .= "<div id=\"reply_" . $comment_id . "\" class=\"reply_box\">";
				    $UserCommentsHTML .= "<h2>Post a Reply</h2>\n";
                                    $UserCommentsHTML .= "<form id=\"add_comment\" parent=\"$comment_id\" user=\"$username\" latest=\"$latest_reply\" group=\"$GroupID\">";
				    $UserCommentsHTML .= "<input type=\"hidden\" name=\"parent_comment\" value=\"" . $comment_id . "\">\n";
				    $UserCommentsHTML .= "<textarea id=\"comment_box_" . $comment_id . "\" rows=\"4\" cols=\"44\" name=\"comment_box_" . $comment_id . "\"></textarea>\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "<input type=\"submit\" value=\"Reply\" style=\"float: right; margin-right: 25px; margin-top: 5px; margin-bottom: 5px;\" class=\"removable\">\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "</form>\n";
				    $UserCommentsHTML .= "</div>\n";
				}
                                
                                $UserCommentsHTML .= "<br clear=\"all\">\n";
                                $UserCommentsHTML .= "<a href=\"#top\" class=\"back_to_top_link\"><img src=\"/static/images/icons/backtotop.gif\" border=\"0\" height=\"24\" width=\"24\"> Back to Top</a><p />\n";
				$UserCommentsHTML .= "</div>\n";
    } else {
	$UserCommentsHTML .= "I can't find this comment.";
    }

    # Is this the wrong profile?
    
    unless ( ($comment_owner) && ($GroupID == $comment_owner) ) {
	$UserCommentsHTML = "I can't find this comment.";
    }
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff   
    
    $c->stash->{IsOwner}       = $IsOwner;
    $c->stash->{IsAdmin}       = $IsAdmin;
    $c->stash->{IsMember}      = $IsMember;
    $c->stash->{IsJoinRequest} = $IsJoinRequest;
    $c->stash->{IsPrivate}     = $Group->is_private;
    $c->stash->{group}         = $Group;
    $c->stash->{GroupComments} = $UserCommentsHTML;
    $c->stash->{user}          = $User;
    $c->stash->{autoScroll}    = $autoScroll;
    $c->stash->{metadate}    = $metadisplaydate;
    $c->stash->{metadescription} = $metadescription;    
    $c->stash->{template}      = 'groups/individual_reply.tt2';
}



sub view_group :Path('/groups') :Args(2) {
    my ( $self, $c, $GroupID, $pretty_url ) = @_;
    my $MembersHTML;
    my $UserID;

    my $cpage = $c->req->params->{'cpage'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }
    
    my $User = $c->model('DB::Users')->find({
        id => $UserID,
    });
    
    my $g =$c->model('Groups::Group');
    $g->build( $c, $GroupID );
    my $created_by = $g->created_by_user_id;
    my $is_private = $g->is_private;
    $g->get_group_profile_image( $c );


    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );


    # Maybe their have been some invites?
    my $Invites = $c->model('DB::GroupInvites')->search({
        group_id => $GroupID,
        user_id => $UserID,
    });
            
    if ($Invites) {
        $c->stash->{Invites} = $Invites;
    }

    
    # Is there anyone who has requested to join this group?
    
    my $NumJoinRequests = WorldOfAnime::Controller::DAO_Groups::GetNumJoinRequests( $c, $GroupID );

    ##### Get User Comments
    my $UserCommentsHTML;
    my $UserComments;
    
    unless ($UserComments) {
        $UserComments = $c->model("DB::GroupComments")->search({
            group_id => $GroupID,
	},{
	  page      => "$cpage",
	  rows      => 10,
	  order_by  => 'createdate DESC',
	  });
    }

	my $cpager = $UserComments->pager();

	      while (my $comment = $UserComments->next) {
                            eval {
	    			my $comment_id    = $comment->id;
                                
                                my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $comment->group_commentors->id );

				my $username   = $u->{'username'};

				my $p = $c->model('Users::UserProfile');
				$p->get_profile_image( $c, $u->{'id'} );
				my $profile_image_id = $p->profile_image_id;
						
				my $i = $c->model('Images::Image');
				$i->build($c, $profile_image_id);
				my $profile_image_url = $i->thumb_url;	
                                
                                my $user_comment  = WorldOfAnime::Controller::Root::ResizeComment($comment->comment, 370);
	    			my $date          = $comment->createdate;
				my $displayDate    = WorldOfAnime::Controller::Root::PrepareDate($date, 1);
                                my $latest_reply = 0;
				
				$user_comment =~ s/\n/<br \/>/g;

				$UserCommentsHTML .= "<div id=\"individual_post\" class=\"comment_" . $comment_id . "\">\n";
				if ($IsAdmin) {
				    $UserCommentsHTML .= "<a href=\"#\" class=\"delete-comment\" id=\"" . $comment_id . "\" group_id=\"" . $GroupID . "\" type=\"comment\"><div id=\"delete_button\">delete</div></a>\n";
				}


				$UserCommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" class=\"comment_image\"></a>";				

			
				$UserCommentsHTML .= "<span class=\"post\">$user_comment</span>\n";
                                $UserCommentsHTML .= "<br clear=\"all\">\n";
        			$UserCommentsHTML .= "<span class=\"post_byline\">Posted by $username on $displayDate</span>\n";

                                my ($latest, $RepliesHTML) = WorldOfAnime::Controller::DAO_Users::GetGroupCommentReplies($self, $c, $comment->id, $GroupID );
				$UserCommentsHTML .= "<p> $RepliesHTML </p>\n" if ($RepliesHTML);
                                $latest_reply = $latest if ($latest);
                                $UserCommentsHTML .= "<div class=\"replies_" . $comment->id . "\"><p> </p></div>\n"; # Create empty div to pull in replies via Ajax

				if ($IsMember) {
				    $UserCommentsHTML .= "<div id=\"setup_reply_" . $comment_id . "\" style=\"text-align: right;\"><a href=\"#\" class=\"reply_linky\" onclick=\"javascript:\$('#reply_" . $comment_id . "').show();\$('#add_comment #comment_box_" . $comment_id . "').focus();\$('#setup_reply_" . $comment_id . "').hide();return false\">Post a Reply</a></div>\n";
				}
                                
				if ($IsMember) {
				    $UserCommentsHTML .= "<div id=\"reply_" . $comment_id . "\" class=\"reply_box\">";
				    $UserCommentsHTML .= "<h2>Post a Reply</h2>\n";
                                    $UserCommentsHTML .= "<form id=\"add_comment\" parent=\"$comment_id\" user=\"$username\" latest=\"$latest_reply\" group=\"$GroupID\">";
				    $UserCommentsHTML .= "<input type=\"hidden\" name=\"parent_comment\" value=\"" . $comment_id . "\">\n";
				    $UserCommentsHTML .= "<textarea id=\"comment_box_" . $comment_id . "\" rows=\"4\" cols=\"44\" name=\"comment_box_" . $comment_id . "\"></textarea>\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "<input type=\"submit\" value=\"Reply\" style=\"float: right; margin-right: 25px; margin-top: 5px; margin-bottom: 5px;\" class=\"removable\">\n<br clear=\"all\">\n";
				    $UserCommentsHTML .= "</form>\n";
				    $UserCommentsHTML .= "</div>\n";
				}
                                
                                $UserCommentsHTML .= "<br clear=\"all\">\n";
        			$UserCommentsHTML .= "</div>\n";
                            } # end eval
	    	}
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff   
    
    $c->stash->{IsOwner}       = $IsOwner;
    $c->stash->{IsAdmin}       = $IsAdmin;
    $c->stash->{IsMember}      = $IsMember;
    $c->stash->{IsJoinRequest} = $IsJoinRequest;
    $c->stash->{IsPrivate}     = $is_private;
    $c->stash->{group}         = $g;
    $c->stash->{current_uri}   = $current_uri;
    $c->stash->{cpager}        = $cpager;
    $c->stash->{GroupComments} = $UserCommentsHTML;
    $c->stash->{JoinRequests}  = $NumJoinRequests;
    $c->stash->{user}           = $User;
    $c->stash->{template}      = 'groups/group.tt2';
}


sub ajax_branch2 :Path('/groups/ajax') :Args(2) {
    my ( $self, $c, $action, $arg1 ) = @_;
    
    if ($action eq "load_profile_replies") {
	$c->forward('ajax_groups_load_profile_replies');
    }

    if ($action eq "add_reply") {
	$c->forward('ajax_groups_add_reply');
    }
}


sub ajax_groups_load_profile_replies :Local {
    my ( $self, $c, $action, $parent_comment ) = @_;
    my $Body;
    
    my $latest = $c->req->param('latest');
    my $group  = $c->req->param('group');
    
    my $RepliesHTML = WorldOfAnime::Controller::DAO_Users::GetGroupCommentReplies($self, $c, $parent_comment, $group, 0, $latest );
    $Body .= "<div class=\"replies_" . $parent_comment . "\"><p> $RepliesHTML </p></div>\n";
    
    $c->response->body($Body);
}


sub ajax_groups_add_reply :Local {
    my ( $self, $c, $action, $parent_comment ) = @_;
    my $UserID;
    my $body;
    my $Email;
    
    my $GroupID    = $c->req->param('group');
    

    ### Make sure commentor is logged in before doing this
    
    if ($c->user_exists()) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    } else {
	return 0;
    }
    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
   
    my $GroupName = $Group->name;
    my $pretty_url = $Group->pretty_url;
    
    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }


    ### If they aren't a member, don't let them do this
    
    unless ($IsMember) {
        return 0;
    }

    my $user    = $c->req->param('user');
    my $comment = $c->req->param('post');
    
    
    my $Commentor = $c->model('DB::Users')->find({
        id => $UserID,
    });
    
    my $CommentorUsername = $Commentor->username;
    
    
    ### Figure out where the comment goes

    my $Comment = $c->model("DB::GroupCommentReplies")->create({
        parent_comment_id => $parent_comment,
        comment_user_id => $UserID,
        comment         => $comment,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    my $CommentID = $Comment->id;

    ### For every member of the group...
    ### Do they want to know about it?

    
    my $Members = $c->model('DB::GroupUsers')->search({
            group_id => $GroupID,
    });
    
    while (my $m = $Members->next) {
        
        if ($m->user_id->user_profiles->notify_group_comment) {

	$body = <<EndOfBody;
A new reply has been posted to the group $GroupName

To view the new reply, go to http://www.worldofanime.com/groups/$GroupID/$pretty_url/reply/$CommentID

If you do not want to receive e-mail notifications when you receive a new comment anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $m->user_id->email, 1, $body, 'New Group Reply');

	    }
        
            ### Create Notification
    
	unless ($UserID == $m->user_id->id) {  # Don't send the notification to yourself
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $m->user_id->id, "<a href=\"/profile/$CommentorUsername\">$CommentorUsername</a> posted a <a href=\"/groups/$GroupID/$pretty_url/reply/$CommentID\">reply</a> on the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 36);
	}
        
    }


    ### Create User Action
    
        my $ActionDescription = "<a href=\"/profile/" . $CommentorUsername . "\">" . $CommentorUsername . "</a> posted a ";
        
        if ($Group->is_private) {
            $ActionDescription   .= "reply on a group";
        } else {
            $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url/reply/$CommentID\">reply</a> on the group <a href=\"/groups/$GroupID/$pretty_url\">" . $GroupName . "</a>";
        }
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $UserID,
	action_id => 20,
	action_object => $GroupID,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    $c->cache->remove("worldofanime:group_comment_replies_json:$parent_comment");
    
    $c->response->body("success");
}





sub setup_edit :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
            # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    # Get Profile Image
    my $ProfileImage = $c->model("DB::Images")->find({
        id => $Group->profile_image_id,
    });
    
    my $filedir = $ProfileImage->filedir;
    $filedir =~ s/u\/$/t175\//;
    
    my $imagefile = defined($ProfileImage) ? $filedir . $ProfileImage->filename : "";

    $c->stash->{thumbnail_image} = "<img src=\"/$imagefile\">\n";
    $c->stash->{IsOwner}  = $IsOwner;
    $c->stash->{IsAdmin}  = $IsAdmin;
    $c->stash->{group}    = $Group;
    $c->stash->{template} = 'groups/setup_edit.tt2';
}


sub update_group :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $DesiredWidth;
    my $ThumbImage;
    my $ThumbWidth;
    my $ThumbHeight;

    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $g =$c->model('Groups::Group');
    $g->build( $c, $GroupID );

    
    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
            # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }

    unless ($IsOwner) {
        $c->stash->{error_message} = "Hey, you don't own this group!  What are you trying to do?";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }
    
    unless ($c->req->params->{'do_update'}) {
	$c->response->redirect("/groups/$GroupID/$pretty_url");
    }
    
    my $User = $c->model('DB::Users')->find({
        id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
    });
    
    my $username = $User->username;

    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;    

    # Now, edit stuff

    my $profile_image_id = $g->profile_image_id;
    my $background_image_id = $g->background_image_id;
    
    # Handle image profile
    if ($c->req->params->{profile_image}) {
	my $upload   = $c->req->upload('profile_image');
        my $filename = $upload->filename;
        
        $profile_image_id = WorldOfAnime::Controller::DAO_Images::upload_image( $c, $upload, $filename);
	$g->profile_image_id( $profile_image_id );
    }

    # Handle background image
    if ($c->req->params->{background_image}) {
	my $upload   = $c->req->upload('background_image');
	my $filedir  = 'backgrounds/groups';
        my $filename = $upload->filename;
        
        $background_image_id = WorldOfAnime::Controller::DAO_Images::upload_image( $c, $upload, $filename, $filedir);
	$g->background_image_id( $background_image_id );
    }
    
    # If they want their background image gone, do it!
    
    $g->background_image_id(0) if ($c->req->params->{'remove_background_image'});
    
    $g->update( $c );
    $g->save( $c );
    

    &LogEvent($c, $GroupID, "Group edited by $HTMLUsername", 11);

    WorldOfAnime::Controller::DAO_Groups::CleanGroup( $c, $GroupID );
    
    $c->response->redirect("/groups/$GroupID/$pretty_url");
}


### Delete a comment

sub delete_comment :Path('/groups/comment/delete') :Args(0) {
    my ( $self, $c ) = @_;

    my $id      = $c->req->param('comment');
    my $GroupID = $c->req->param('group_id');
    my $type    = $c->req->param('type');
    my $UserID  = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });    

    my $User = $c->model('DB::Users')->find({
        id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
    });
    
    my $username = $User->username;

    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    
    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    

    my $Comment;
    
    if ($IsAdmin) {
        if ($type eq "reply") {
            $Comment = $c->model("DB::GroupCommentReplies")->find({
                id             => $id,
            });
        } elsif ($type eq "comment") {
            $Comment = $c->model("DB::GroupComments")->find({
                id             => $id,
            });

        }
    
        $Comment->delete;
        
        &LogEvent($c, $GroupID, "Comment deleted by $HTMLUsername", 12);
    }
}


sub add_comment :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $body;
    my $Email;

    # Make sure commentor is logged in before doing this
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a comment.");    
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $g = WorldOfAnime::Controller::DAO_Groups::GetCacheableGroupByID( $c, $GroupID );
    my $GroupName  = $g->{'name'};
    my $is_private = $g->{'is_private'};

    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }

    # If they aren't a member, don't let them do this
    
    unless ($IsMember) {
        $c->response->redirect("/groups/$GroupID/$pretty_url");
    }

    my $comment = $c->req->params->{'comment'};
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $UserID );
    my $CommentorUsername = $u->{'username'};
    
    # Figure out where the comment goes

    my $Comment = $c->model("DB::GroupComments")->create({
        group_id        => $GroupID,
        comment_user_id => $UserID,
        comment         => $comment,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    my $CommentID = $Comment->id;

    # For every member of the group...
    # Do they want to know about it?

    my $members;
    my $members_json = WorldOfAnime::Controller::DAO_Groups::GetGroupMembers_JSON( $c, $GroupID );
    if ($members_json) { $members = from_json( $members_json ); }

    #while (my $m = $Members->next) {

    foreach my $m (@{ $members}) {
	
	my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $m->{id} );
        
        if ($e->{group_comment}) {

            $body = <<EndOfBody;
A new comment has been posted to the group $GroupName

To view the new comment, go to http://www.worldofanime.com/groups/$GroupID/$pretty_url/comment/$CommentID

If you do not want to receive e-mail notifications when you receive a new group comment anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $m->{email}, 1, $body, 'New Group Comment');

	    }

        ### Create Notification
    
	unless ($UserID == $m->{id}) {  # Don't send the notification to yourself
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $m->{id}, "<a href=\"/profile/$CommentorUsername\">$CommentorUsername</a> posted a <a href=\"/groups/$GroupID/$pretty_url/comment/$CommentID\">comment</a> on the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 36);
	}

    }

        ### Create User Action
    
        my $ActionDescription = "<a href=\"/profile/" . $CommentorUsername . "\">" . $CommentorUsername . "</a> posted a ";
        
        if ($is_private) {
            $ActionDescription   .= "comment on a group";
        } else {
            $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url/comment/$CommentID\">comment</a> on the group <a href=\"/groups/$GroupID/$pretty_url\">" . $GroupName . "</a>";
        }
    
        my $UserAction = $c->model("DB::UserActions")->create({
            user_id => $UserID,
            action_id => 20,
            action_object => $GroupID,
            description => $ActionDescription,
            modify_date => undef,
            create_date => undef,
        });
    
    my $Commentor = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, $UserID );
    
    ### End User Action
    
    $c->response->redirect("/groups/$GroupID/$pretty_url");
}



sub view_gallery :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $MembersHTML;
    my $UserID;

    my $page = $c->req->params->{'page'} || 1;    

    my $Gallery;
    my $Images;
    my $ImagesHTML;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });


    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    # Now, we need to find this users default gallery ID

    $Gallery = $c->model("DB::GroupGalleries")->find({
        group_id      => $GroupID,
        gallery_name => 'Default Gallery'
    });

    my $gallery_id = $Gallery ? $Gallery->id : 0;



    # Now, get this galleries images
        
    if ($gallery_id) {
        $Images = $c->model("DB::GroupGalleryImages")->search({
            group_gallery_id => $gallery_id,
            active     => 1,
        },{
            order_by => 'createdate DESC',
      	    		page      => "$page",
    			rows      => 12,
  	});

    			my $pager = $Images->pager();

    			$c->stash->{pager}    = $pager;
        }
        
        if ($Images) {
            while (my $image = $Images->next) {
                my $image_id  = $image->id;
		
		my $i = $c->model('Images::Image');
		$i->build($c, $image->image_images->id);
                my $thumb_url = $i->thumb_url;
		
                my $num_views = $image->num_views;
                my $title     = $image->title;
			
                $ImagesHTML .= "<div id=\"image_profile_box\">\n";
                $ImagesHTML .= "<a href=\"images/$image_id\"><img src=\"$thumb_url\" border=\"0\" alt=\"$title\" title=\"$title\"></a><p />\n";				
                $ImagesHTML .= "<span class=\"image_profile_info\">$num_views Views<br />\n";
                $ImagesHTML .= $image->gallery_image_comments . " comments</span>";
                $ImagesHTML .= "</div>\n";
            }
	}

      	  
    
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff   
    
    $c->stash->{IsOwner}      = $IsOwner;
    $c->stash->{IsAdmin}      = $IsAdmin;
    $c->stash->{IsMember}     = $IsMember;
    $c->stash->{IsPrivate}    = $Group->is_private;
    $c->stash->{group}        = $Group;
    $c->stash->{current_uri}  = $current_uri;
    $c->stash->{images}    = $ImagesHTML;
    $c->stash->{template} = 'groups/gallery.tt2';
}


sub view_members :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $MembersHTML;
    my $UserID;

    my $cpage = $c->req->params->{'cpage'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $g = $c->model('Groups::Group');
    $g->build( $c, $GroupID );
    $g->get_group_profile_image( $c );


    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
    # Get members HTML

    my $m = $c->model('Groups::GroupMembers');
    $m->build( $c, $GroupID );
    my $members;
    my $count;
    
    if ($m->members) {
	$members = from_json( $m->members );
	$count = $m->member_count;
    }

    foreach my $member (@{ $members}) {

	my $member_id = $member->{'id'};

	my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $member_id );

	my $p = $c->model('Users::UserProfile');
	$p->get_profile_image( $c, $member_id );
	my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
			
	my $i = $c->model('Images::Image');
	$i->build($c, $profile_image_id);
	my $profile_image_url = $i->small_url;	

	my $username   = $member->{'name'};
	my $joindate   = $member->{'join_date'};


	my $mult    = ($height / 175);
	my $new_height = int( ($height/$mult) / 1.6 );
	my $new_width  = int( ($width/$mult) / 1.6 );				

	my $displayJoindate = WorldOfAnime::Controller::Root::PrepareDate($joindate, 1);

	my $tip = "$username<br>Member since $displayJoindate";
	$MembersHTML .= "	<a href=\"/profile/$username\"><img src=\"$profile_image_url\" height=\"$new_height\" width=\"$new_width\" image_desc=\"$tip\"></a>";
    }

    $c->stash->{IsOwner}      = $IsOwner;
    $c->stash->{IsAdmin}      = $IsAdmin;
    $c->stash->{IsMember}     = $IsMember;
    $c->stash->{IsPrivate}    = $g->is_private;
    $c->stash->{MembersHTML}  = $MembersHTML;
    $c->stash->{group}        = $g;
    $c->stash->{count}        = $count;
    $c->stash->{template} = 'groups/members.tt2';
}



sub update_image :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $image_id, $action2 ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit an image.");

    my $image = $c->model('DB::GroupGalleryImages')->find( {
	id => $image_id,
    });
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($image->group_image_gallery->group_galleries->id == $GroupID) {
	$c->stash->{error_message} = "Huh?  This image doesn't belong to this group.  Wait, how did you get here?";
        $c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
	
    
    # If they made it here, its ok to modify the image
    
    my $title = $c->req->params->{title};
    my $desc  = $c->req->params->{description};
    
    $image->update({
	title => $title,
	description => $desc,
    });

    $c->response->redirect("/groups/$GroupID/$pretty_url/images/$image_id"); 
}



sub add_image :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $action2 ) = @_;
    my $UserID;
    my $DesiredWidth;
    my $ThumbImage;
    my $ThumbWidth;
    my $ThumbHeight;
    my $body;
    my $Email;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add an image.");

    $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    
    # Handle image uploads
    
    if ($c->req->params->{image}) {
	
	my $image_title = $c->req->params->{image_title};
	my $image_desc  = $c->req->params->{image_description};

        # First, upload it and create an Image entry for it

        my $upload   = $c->req->upload('image');
        my $filedir  = $c->config->{uploadfiledir};
        my $justfilename = $upload->filename;
        # Strip off anything before the final / in the filename
        if ($justfilename =~ /\\/) { $justfilename =~ s/(.*)\\(.*)/$2/; }
        
        my $filename = WorldOfAnime::Controller::Helpers::Users::GetUserID($c) . "_" . $GroupID . "_" . $justfilename;
                
        my $filesize = $upload->size;
        my $filetype = $upload->type;
        
        my $fileloc = $filedir . $filename;
	my $copytodir = $c->config->{baseimagefiledir};
        $upload->copy_to($copytodir . "u/$filename");


        # Image Magick stuff, for figuring out width and height
	
        my $i = Image::Magick->new;
        $i->Read($copytodir . "u/{$filename}[0]");
				my $width = $i->Get('columns');
				my $height = $i->Get('rows');


				### Thumbnail Image 1
				#
				$DesiredWidth = 175;
		
				$ThumbImage  = $i;
				$ThumbWidth  = $width;
				$ThumbHeight = $height;
		
				if ($ThumbWidth > $DesiredWidth)
				{
					$ThumbHeight = int(($ThumbHeight / $ThumbWidth) * $DesiredWidth);
					$ThumbWidth = $DesiredWidth;
			
					$ThumbImage->Thumbnail(Width => $ThumbWidth,
			                   Height => $ThumbHeight);
				}
		
			$ThumbImage->Write($copytodir . "t175/$filename");




				### Thumbnail Image 2
				#
				$DesiredWidth = 80;
		
				$ThumbImage  = $i;
				$ThumbWidth  = $width;
				$ThumbHeight = $height;
		
				if ($ThumbWidth > $DesiredWidth)
				{
					$ThumbHeight = int(($ThumbHeight / $ThumbWidth) * $DesiredWidth);
					$ThumbWidth = $DesiredWidth;
			
					$ThumbImage->Thumbnail(Width => $ThumbWidth,
			                   Height => $ThumbHeight);
				}
		
			$ThumbImage->Write($copytodir . "t80/$filename");

				
        # Now, remove root/ from the filedir before storing
        $filedir =~ s/^root\///;
        
        my $Image = $c->model("DB::Images")->create({
            user_id  => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
            filedir  => $filedir,
            filename => $filename,
            filetype => $filetype,
            filesize => $filesize,
            height   => $height,
            width    => $width,
            modify_date => undef,
            create_date => undef,
        });
        
        my $image_id = $Image->id;

        # Now, we need to find this groups default gallery ID

        my $Gallery = $c->model("DB::GroupGalleries")->find({
            group_id      => $GroupID,
            gallery_name => 'Default Gallery'
        });

        my $gallery_id = $Gallery ? $Gallery->id : 0;
        
        # If no gallery_id, make a new one and set it
        
        unless ($gallery_id) {
            $Gallery = $c->model("DB::GroupGalleries")->create({
                group_id      => $GroupID,
                gallery_name => 'Default Gallery',
                num_images   => 0,
                modifydate   => undef,
                createdate   => undef,
            });
            
            $gallery_id = $Gallery->id;
        }

        # Now, create a gallery image

        my $GalleryImage = $c->model("DB::GroupGalleryImages")->create({
            group_gallery_id  => $gallery_id,
            image_id    => $image_id,
            num_views   => 0,
            active      => 1,
	    title       => $image_title,
	    description => $image_desc,
            uploaded_by => $UserID,
            modifydate  => undef,
            createdate  => undef,
        });
	
        my $GalleryImageID = $GalleryImage->id;
        my $OwnerID        = $GalleryImage->image_owner->id;
        my $UploadedBy     = $GalleryImage->image_owner->username;
        my $GroupName      = $GalleryImage->group_image_gallery->group_galleries->name;
        
        my $HTMLUsername = $UploadedBy;
        $HTMLUsername =~ s/ /%20/g;

	### Create User Action
    
        my $ActionDescription = "<a href=\"/profile/" . $UploadedBy . "\">" . $UploadedBy . "</a> posted a ";
        
        if ($Group->is_private) {
            $ActionDescription .= "new image in a group image gallery";
        } else {
            $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url/images/$GalleryImageID\">new image</a> in the image gallery for the group ";
            $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url\">" . $GroupName . "</a>";
        }
    
        my $UserAction = $c->model("DB::UserActions")->create({
        	user_id => $OwnerID,
        	action_id => 18,
        	action_object => $GalleryImageID,
        	description => $ActionDescription,
        	modify_date => undef,
        	create_date => undef,
        });

        ### End User Action
	
	
    # Email members

    $body = <<EndOfBody;
$UploadedBy has uploaded a new image to the image gallery for the group $GroupName

You can see it at http://www.worldofanime.com/groups/$GroupID/$pretty_url/images/$GalleryImageID

To stop receiving these notices, log on to your profile at http://www.worldofanime.com/ and change your preference by unchecking When a member uploads an image in the Group Notifications
EndOfBody
    
    my $Members = $c->model("DB::GroupUsers")->search({
        group_id => $GroupID,
    },{
                select   => [qw/user_id modifydate/],
                distinct => 1,
		order_by => 'modifydate DESC',
    });
    
    while (my $m = $Members->next) {
        
	if ($m->user_id->user_profiles->notify_group_member_upload_image) {
	    my $email_address = $m->user_id->email;
	    
	    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $email_address, 1, $body, "$UploadedBy has uploaded a new Group Image.");

	}
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $m->user_id->id, "<a href=\"/profile/$HTMLUsername\">$UploadedBy</a> has uploaded a <a href=\"/groups/$GroupID/$pretty_url/images/$GalleryImageID\">new image</a>", 2);
    }  
	
	
	

    }
        

    $c->response->redirect("/groups/$GroupID/$pretty_url/gallery");
}


sub view_image :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action, $image_id ) = @_;
    my $Image;
    my $UserID;

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $page = $c->req->params->{'page'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });


    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    # Get this image
    
    my $ImageSQL = $c->model("DB::GroupGalleryImages")->search({
        id => $image_id,
    });
        
    $Image = $ImageSQL->first;


    # If this image is inactive
				
    unless ($Image->active) {
            $c->stash->{group}       = $Group;
	    $c->stash->{reject_message} = "I can't find this image.  It might have been deleted by an admin.";
	    $c->stash->{template}    = 'groups/view_gallery_image.tt2';
	    $c->detach();
    }
								

    # If this is not this persons image, then detach with error
				
    unless ($Image->group_image_gallery->group_galleries->id == $GroupID) {
            $c->stash->{group}       = $Group;
	    $c->stash->{reject_message} = "What in the world???  That image doesn't appear to belong to this group.";
	    $c->stash->{template}    = 'groups/view_gallery_image.tt2';
	    $c->detach();
    }
	
    
        # Now, increment the counter (unless it is me viewing)
    
        unless ($UserID == 3) {
            $Image->update({
                num_views => $Image->num_views + 1,
            });
        }
    
    # Now, get these image comments
    
    my $ImageComments = $c->model("DB::GroupGalleryImageComments")->search({
        group_gallery_image_id => $image_id
    },{
      });

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff

    my $metadate = $Image->createdate;
    my $metadisplaydate   = WorldOfAnime::Controller::Root::PrepareDate($metadate, 1, $tz);
    
    $c->stash->{IsOwner}      = $IsOwner;
    $c->stash->{IsAdmin}      = $IsAdmin;
    $c->stash->{IsMember}     = $IsMember;
    $c->stash->{IsPrivate}    = $Group->is_private;
    $c->stash->{image}       = $Image;    
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{group}       = $Group;
    $c->stash->{comments}    = $ImageComments;
    $c->stash->{metadisplaydate} = $metadisplaydate;
    $c->stash->{template}    = 'groups/view_gallery_image.tt2';
}


sub add_comment_image :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $image_id, $action3 ) = @_;
    my $body;
    my $Email;

    # Make sure the person can do this
    # (IsMember)
    

    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    
    my $comment = $c->req->param('comment');
    my $commentor_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Who is this from?
		
    my $From = $c->model("DB::Users")->find({
    	id => $commentor_id
    });
    
    my $FromUsername = $From->username;
   
    
    my $Comment = $c->model("DB::GroupGalleryImageComments")->create({
        group_gallery_image_id => $image_id,
        comment_user_id => $commentor_id,
        comment         => $comment,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    my $GroupName = $Comment->group_gallery_image_id->group_image_gallery->group_galleries->name;


    # Email members

    $body = <<EndOfBody;
$FromUsername has posted a new comment on an image in the gallery for group $GroupName

You can see it at http://www.worldofanime.com/groups/$GroupID/$pretty_url/images/$image_id

To stop receiving these notices, log on to your profile at http://www.worldofanime.com/ and change your preference by unchecking New Group Image Gallery Comment in the Group Notifications
EndOfBody
    
    my $Members = $c->model("DB::GroupUsers")->search({
        group_id => $GroupID,
    },{
                select   => [qw/user_id modifydate/],
                distinct => 1,
		order_by => 'modifydate DESC',
    });
    
    while (my $m = $Members->next) {
        
	if ($m->user_id->user_profiles->notify_group_image_comment) {
	    my $email_address = $m->user_id->email;
	    
	    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $email_address, 1, $body, 'New Group Gallery Image Comment.');

	}
        
        
        # Send notification
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $m->user_id->id, "<a href=\"/profile/$FromUsername\">$FromUsername</a> commented on an <a href=\"/groups/$GroupID/$pretty_url/images/$image_id\">image</a> in the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 28);
        
    }
    

    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> posted a comment on a group gallery image";
    
    my $UserAction = $c->model("DB::UserActions")->create({
       	user_id => $commentor_id,
       	action_id => 19,
       	action_object => $image_id,
       	description => $ActionDescription,
    	modify_date => undef,
        create_date => undef,
    });

    ### End User Action
	
    $c->response->redirect("/groups/$GroupID/$pretty_url/$action1/$image_id");  
}



sub delete_image :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $image_id, $action3 ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to delete an image.");

    my $image = $c->model('DB::GroupGalleryImages')->find( {
	id => $image_id,
    });
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $User = $c->model('DB::Users')->find({
        id => $UserID,
    });
    
    my $username = $User->username;

    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    
    unless ($image->group_image_gallery->group_galleries->id == $GroupID) {
	$c->stash->{error_message} = "Huh?  This isn't your image.  Wait, how did you get here?";
        $c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
	
    
    # If they made it here, its ok to delete the image

    $image->update({
        	active => 0,
        	modifydate => undef,
        });

    &LogEvent($c, $GroupID, "Image deleted by $HTMLUsername", 13);

    $c->response->redirect("/groups/$GroupID/$pretty_url/gallery"); 
}






###########  Answers Stuff

sub group_answers :Local {
    my ( $self, $c, $GroupID, $pretty_url ) = @_;
    my $AnswersHTML;
    my $UserID;

    my $page = $c->req->params->{'page'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });

    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    
    my $Questions = $c->model('DB::QAQuestions')->search({
	group_id => $GroupID,
    }, {
        order_by => 'create_date DESC',
        });
    
    $AnswersHTML .= "<div id=\"posts\">\n";
    
    while (my $question = $Questions->next) {
        
        my $asked_by_user_id = $question->asked_by;
        my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $asked_by_user_id );
	
	# Count answers
	my $answer_count = $question->qa_answers;
	my $answer_text  = $answer_count . " answer";
	unless ($answer_count == 1) { $answer_text .= "s"; }
	
	my $username   = $u->{'username'};

	my $p = $c->model('Users::UserProfile');
	$p->get_profile_image( $c, $u->{'id'} );
	my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
			
	my $i = $c->model('Images::Image');
	$i->build($c, $profile_image_id);
	my $profile_image_url = $i->thumb_url;	
        
	my $mult    = ($height / 80);

	my $new_height = int( ($height/$mult) / 1.5 );
	my $new_width  = int( ($width/$mult) /1.5);
	my $ask_date = $question->create_date;
	my $displayAskDate = WorldOfAnime::Controller::Root::PrepareDate($ask_date, 1);
        
	$AnswersHTML .= "<div id=\"qa_box\">\n";
	$AnswersHTML .= "<table border=\"0\">\n";
	$AnswersHTML .= "	<tr>\n";
	$AnswersHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
	$AnswersHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" height=\"$new_height\" width=\"$new_width\"></a>";
	$AnswersHTML .= "		</td>\n";
	$AnswersHTML .= "		<td valign=\"top\" width=\"360\">\n";
	$AnswersHTML .= "			<span class=\"qa_subject\"><a href=\"/groups/$GroupID/$pretty_url/answers/" . $question->id . "\">" . $c->model('Formatter')->clean_html($question->subject) . "</a></span>\n";
	$AnswersHTML .= "		</td>\n";
	$AnswersHTML .= "	</tr>\n";
	$AnswersHTML .= "	<tr>\n";
	$AnswersHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Asked by $username on $displayAskDate | $answer_text</span></td>\n";
	$AnswersHTML .= "	</tr>\n";
	$AnswersHTML .= "</table>\n";
	$AnswersHTML .= "</div>\n\n";
	$AnswersHTML .= "<p />\n";        
    }
    
    $AnswersHTML .= "</div>\n";

    my $jquery = <<EndOfHTML;
<script type="text/javascript">
    \$(function() {    
	\$('.removable_button').submit(function() {
            \$('.removable').remove();
	});
    });
</script>
EndOfHTML

    $c->stash->{jquery}       = $jquery;
    $c->stash->{AnswersHTML} = $AnswersHTML;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{IsOwner}      = $IsOwner;
    $c->stash->{IsAdmin}      = $IsAdmin;
    $c->stash->{IsMember}     = $IsMember;
    $c->stash->{IsPrivate}    = $Group->is_private;
    $c->stash->{group}       = $Group;    
    $c->stash->{template} = 'groups/answers/main.tt2';
}


sub add_new_group_question :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1 ) = @_;
    my $AnswersHTML;
    my $UserID;

    my $page = $c->req->params->{'page'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    my $GroupName = $Group->name;

    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    # Check to make sure they are logged in, or show error
    
    unless ($IsMember) {
        $c->stash->{error_message} = "You must be a member of this group to add a new question.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }
    
    # Who is asking this?
		
    my $Asker = $c->model("DB::Users")->find({
    	id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
    });
    
    my $username = $Asker->username;

    my $subject   = $c->req->params->{'subject'};
    my $question  = $c->req->params->{'question'};
    my $subscribe = $c->req->params->{'subscribe'};
    
    # If they haven't entered a question name or subject, send back
    
    unless ($subject && $question) {
        $c->stash->{error_message} = "You must enter a subject and a question.";
        $c->stash->{subject}    = $subject;
        $c->stash->{question}   = $question;
        $c->stash->{subscribe}  = $subscribe;
        $c->stash->{template}      = 'error_page.tt2';
        
        my $current_uri = $c->req->uri;
        $current_uri =~ s/\?(.*)//; # To remove the pager stuff    

        $c->stash->{current_uri} = $current_uri;
        $c->detach();        
    }
    
    # Create the question
    
    my $Question = $c->model('DB::QAQuestions')->create({
        asked_by => $Asker->id,
	group_id => $GroupID,
        subject  => $subject,
        question => $question,
        modify_date => undef,
        create_date => undef,
    });
    
    my $QuestionID = $Question->id;

    # If they want to subcribe, add them
    
    if ($subscribe) {
        
        my $QAUser = $c->model('DB::QASubscriptions')->create({
            question_id => $Question->id,
            user_id  => $Asker->id,
            modify_date => undef,
            create_date => undef,
        });
    }
    
    # Always subscribe me
    
    my $Sub = $c->model('DB::QASubscriptions')->create({
        question_id => $Question->id,
        user_id => 3,
        modify_date => undef,
        create_date => undef,
    });    
    
    # Add action points
    
    my $ActionDescription = "<a href=\"/profile/" . $Asker->username . "\">" . $Asker->username . "</a> posted a new ";

    if ($Group->is_private) {
        $ActionDescription   .= "question on a group";
    } else {
        $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url/answers/" . $Question->id . "\">question</a> on the group ";
        $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url\">" . $GroupName . "</a>";
    }
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Asker->id,
	action_id => 13,
	action_object => $Question->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
   

    # Notify members of new question
    
    my $Members = $c->model('DB::GroupUsers')->search({
            group_id => $GroupID,
    });
    
    while (my $m = $Members->next) {

            my $body = <<EndOfBody;
A new question has been asked on the group $GroupName

To view the new question, go to http://www.worldofanime.com/groups/$GroupID/$pretty_url/answers/$QuestionID

You can also subscribe to this question from the URL above, which will send you notifications whenever an answer is posted to it.
EndOfBody
    
	    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $m->user_id->email, 1, $body, 'New Group Question.');

        ### Create Notification
    
        WorldOfAnime::Controller::Notifications::AddNotification($c, $m->user_id->id, "<a href=\"/profile/$username\">$username</a> asked a new <a href=\"/groups/$GroupID/$pretty_url/answers/$QuestionID\">question</a> on the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 9);

    }
    
    # Go back to main questions
    
   $c->response->redirect("/groups/$GroupID/$pretty_url/answers");
}


sub display_group_question :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $id ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $UserID;

    my $page = $c->req->params->{'page'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });


    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    # Check to make sure they are logged in, or show error
    
    if ($Group->is_private && !$IsMember) {
        $c->stash->{error_message} = "You must be a member of this group to view this question.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }
    
    my $QuestionHTML;
    my $AnswersHTML;

    my $QA = $c->model('DB::QAQuestions')->search({
	id => $id,
	group_id => $GroupID,
    });
    
    my $question = $QA->first;

    unless ($question) {
	$c->stash->{error_message} = "What?  That doesn't seem like a real question that belongs to this group.";
	$c->stash->{template}    = 'error_page.tt2';
	$c->detach();
    }
    
    
    if ($viewer_id) {
	# Someone is logged in - lets see if they are subscribed to this question
	
	my $Sub = $c->model('DB::QASubscriptions')->find({
	    question_id => $id,
	    user_id   => $viewer_id,
	});
	
	if ($Sub) {
	    $c->stash->{IsSub} = 1;
	}
    }
    
    
    $QuestionHTML .= "<div id=\"posts\">\n";
    
    my $DisplayQuestion = $question->question;
    $DisplayQuestion =~ s/\n/<br \/>/g;
    if ($DisplayQuestion =~ /<a href=(.*)>(.*)</) {
	my $link = $2;
	$link = substr $link, 0, 40;
	$link .= "...";
	$DisplayQuestion =~ s/<a href=(.*)>(.*)<(.*)/<a href=$1>$link<$3/;
    }
    
    $DisplayQuestion  = WorldOfAnime::Controller::Root::ResizeComment($DisplayQuestion, 520);

    my $asked_by_user_id = $question->asked_by;
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $asked_by_user_id );
    
    my $username   = $u->{'username'};

    my $p = $c->model('Users::UserProfile');
    $p->get_profile_image( $c, $u->{'id'} );
    my $profile_image_id = $p->profile_image_id;
		    
    my $i = $c->model('Images::Image');
    $i->build($c, $profile_image_id);
    my $profile_image_url = $i->thumb_url;
    
    my $ask_date = $question->create_date;
    my $displayAskDate = WorldOfAnime::Controller::Root::PrepareDate($ask_date, 1);
        
    $QuestionHTML .= "<div id=\"qa_box\">\n";
    $QuestionHTML .= "<table border=\"0\">\n";
    $QuestionHTML .= "	<tr>\n";
    $QuestionHTML .= "		<td valign=\"top\" rowspan=\"3\">\n";
    $QuestionHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a>";
    $QuestionHTML .= "		</td>\n";
    $QuestionHTML .= "		<td valign=\"top\" width=\"360\">\n";
    $QuestionHTML .= "			<span class=\"qa_subject\">" . $c->model('Formatter')->clean_html($question->subject) . "</span>\n";
    $QuestionHTML .= "                  <span class=\"qa_question\">" . $c->model('Formatter')->clean_html($DisplayQuestion) . "</span>\n";
    $QuestionHTML .= "		</td>\n";
    $QuestionHTML .= "	</tr>\n";
    $QuestionHTML .= "	<tr>\n";
    $QuestionHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Asked by $username on $displayAskDate</span></td>\n";
    $QuestionHTML .= "	</tr>\n";
    if ($IsMember) {
	$QuestionHTML .= "	<tr>\n";
        $QuestionHTML .= "		<td colspan=\"2\" valign=\"bottom\">";
	$QuestionHTML .= "		<div id=\"setup_answer\"><a href=\"#\" class=\"reply_button\" onclick=\"javascript:\$('#answer_question').show();\$('#answer_box #answer_entry').focus();\$('#setup_answer').remove();return false\">Answer Question</a></div>";
	$QuestionHTML .= "<div id=\"answer_question\" style=\"display: none;\" class=\"answer_box\">";
        $QuestionHTML .= "<h2>Answer Question</h2>\n";
	$QuestionHTML .= "<form id=\"answer_box\" class=\"removable_button\" action=\"/groups/$GroupID/$pretty_url/answers/add_new_answer\" method=\"post\">";
        $QuestionHTML .= "<input type=\"hidden\" name=\"question_id\" value=\"" . $question->id . "\">\n";
	$QuestionHTML .= "<textarea id=\"answer_entry\" rows=\"8\" cols=\"54\" name=\"answer\"></textarea>\n<br clear=\"all\">\n";
        $QuestionHTML .= "<input type=\"submit\" value=\"Answer\" style=\"float: right; margin-right: 25px; margin-top: 5px; margin-bottom: 5px;\" class=\"removable\">\n<br clear=\"all\">\n";
	$QuestionHTML .= "</form>\n";
        $QuestionHTML .= "</div>\n";
        $QuestionHTML .= "</td>\n";
        $QuestionHTML .= "	</tr>\n";
    }
    $QuestionHTML .= "</table>\n";
    $QuestionHTML .= "</div>\n\n";
    $QuestionHTML .= "<p />\n";
    
    $QuestionHTML .= "</div>\n";


    # Get answers to question
    
    $AnswersHTML .= "<div id=\"posts\">\n";
    
    my $Answers = $c->model('DB::QAAnswers')->search({
	question_id => $id,
    });
    
    while (my $answer = $Answers->next) {
	my $DisplayAnswer = $answer->answer;
        $DisplayAnswer  = WorldOfAnime::Controller::Root::ResizeComment($DisplayAnswer, 540);
        
	my $answered_by_user_id = $answer->answered_by;
        my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $answered_by_user_id );	        
	
	my $username   = $u->{'username'};

	my $p = $c->model('Users::UserProfile');
	$p->get_profile_image( $c, $u->{'id'} );
	my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
			
	my $i = $c->model('Images::Image');
	$i->build($c, $profile_image_id);
	my $profile_image_url = $i->thumb_url;	

	my $mult    = ($height / 80);

	my $new_height = int( ($height/$mult) / 1.5 );
	my $new_width  = int( ($width/$mult) /1.5);
	
        my $answer_date = $answer->create_date;
	my $displayAnswerDate = WorldOfAnime::Controller::Root::PrepareDate($answer_date, 1);
	
	$DisplayAnswer =~ s/\n/<br \/>/g;
        
        $AnswersHTML .= "<div id=\"qa_box\">\n";
        $AnswersHTML .= "<table border=\"0\">\n";
        $AnswersHTML .= "	<tr>\n";
        $AnswersHTML .= "		<td valign=\"top\" rowspan=\"3\">\n";
        $AnswersHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" height=\"$new_height\" width=\"$new_width\"></a>";
        $AnswersHTML .= "		</td>\n";
        $AnswersHTML .= "		<td valign=\"top\" width=\"360\">\n";
        $AnswersHTML .= "                  <span class=\"qa_question\">" . $c->model('Formatter')->clean_html($DisplayAnswer) . "</span>\n";
        $AnswersHTML .= "		</td>\n";
        $AnswersHTML .= "	</tr>\n";
        $AnswersHTML .= "	<tr>\n";
        $AnswersHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Answered by $username on $displayAnswerDate</span></td>\n";
        $AnswersHTML .= "	</tr>\n";
        $AnswersHTML .= "</table>\n";
        $AnswersHTML .= "</div>\n\n";
        $AnswersHTML .= "<p />\n";
    }
    
    $AnswersHTML .= "</div>\n";

    my $jquery = <<EndOfHTML;
<script type="text/javascript">
    \$(function() {    
	\$('.removable_button').submit(function() {
            \$('.removable').remove();
	});
    });
</script>
EndOfHTML

    $c->stash->{jquery}       = $jquery;    
    $c->stash->{QuestionID}   = $id;
    $c->stash->{QuestionHTML} = $QuestionHTML;
    $c->stash->{AnswersHTML}  = $AnswersHTML;
    $c->stash->{Subject}      = $question->subject;
    $c->stash->{IsOwner}      = $IsOwner;
    $c->stash->{IsAdmin}      = $IsAdmin;
    $c->stash->{IsMember}     = $IsMember;
    $c->stash->{IsPrivate}    = $Group->is_private;
    $c->stash->{group}        = $Group;
    $c->stash->{template} = 'groups/answers/question.tt2';
}


sub add_new_group_answer :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $action2 ) = @_;
    
    my $id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $viewer_id = $id;
    my $UserID;

    my $page = $c->req->params->{'page'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });

    my $GroupName = $Group->name;

    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    # Check to make sure they are a member, or show error
    
    unless ($IsMember) {
        $c->stash->{error_message} = "You must be a member to add a new answer.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }

    # Who is answering this?

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $id );
    
    my $username    =  $u->{'username'};
    
    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    
    my $question_id = $c->req->params->{'question_id'};
    my $answer      = $c->req->params->{'answer'};

    # Write answer
    
    my $Answer = $c->model('DB::QAAnswers')->create({
	question_id => $question_id,
	answered_by => $id,
	answer      => $answer,
	modify_date => undef,
	create_date => undef,
    });
    


    my $subject = $Answer->question->subject;
    my $asker   = $Answer->question->asked_by_user->username;
    my $name    = $asker . "'s";
    
    
    # E-mail whoever is subscribed to this question

    my $Subs = $c->model('DB::QASubscriptions')->search({
	question_id => $question_id,
    });
    
    while (my $s = $Subs->next) {
	# Figure out user in s
	my $User = $s->qa_subscription_user_id;
	
	# Create e-mail object
	
	my $Body;
	
	$Body .= "$username has posted an answer to the question " . $subject . ".  The answer was:\n";
	$Body .= $answer . "\n\n";
	$Body .= "Read the full question and all answers here - http://www.worldofanime.com/groups/$GroupID/$pretty_url/answers/" . $question_id . "\n";
	$Body .= "You can also unsubscribe from this thread from the URL above.";

	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $Body, 'New Answer to a Question.');
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $User->id, "<a href=\"/profile/" . $HTMLUsername . "\">" . $username . "</a> has posted a new answer to <a href=\"/profile/$asker\">$name</a> question <a href=\"/groups/$GroupID/$pretty_url/answers/$question_id\">$subject</a>.", 14);
    }
    
    my $Answerer = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, $id );     
    
    # Add action points
    
    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> posted a new ";
    
    if ($Group->is_private) {
        $ActionDescription .= "answer to a question on a group"
    } else {
        $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url/answers/" . $question_id . "\">answer</a> to a question on the group ";
        $ActionDescription   .= "<a href=\"/groups/$GroupID/$pretty_url\">" . $GroupName . "</a>";
    }
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $id,
	action_id => 14,
	action_object => $Answer->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    # Go back to specific question
    
   $c->response->redirect("/groups/$GroupID/$pretty_url/answers/$question_id");
}




sub groups_branch1 :Path('/groups') :Args(1) {
    my ( $self, $c, $action ) = @_;
    
    if ($action eq "add_new_group") {
        $c->forward('add_new_group');
    }

    if ($action eq "invite") {
	$c->detach('invite_user');
    }
    
    # Default forward
    
    $c->forward('view_group');
}


sub groups_branch3 :Path('/groups') :Args(3) {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    
    if ($action eq "setup_edit") {
        $c->detach('setup_edit');
    }

    if ($action eq "member_maintenance") {
        $c->detach('member_maintenance');
    }
    
    if ($action eq "update_group") {
        $c->detach('update_group');
    }
    
    if ($action eq "add_comment") {
        $c->detach('add_comment');
    }
    
    if ($action eq "reply_comment") {
        $c->detach('reply_comment');
    }

    if ($action eq "join_request") {
        $c->detach('join_request');
    }

    if ($action eq "join_requests") {
        $c->detach('join_requests');
    }

    if ($action eq "reject") {
        $c->detach('reject_join_request');
    }

    if ($action eq "accept") {
        $c->detach('accept_join_request');
    }
    
    if ($action eq "gallery") {
        $c->detach('view_gallery');
    }
    
    if ($action eq "members") {
        $c->detach('view_members');
    }
    
    if ($action eq "answers") {
        $c->detach('group_answers');
    }

    if ($action eq "accept_invite") {
        $c->detach('accept_invite');
    }
    
    if ($action eq "decline_invite") {
        $c->detach('decline_invite');
    }
    
    if ($action eq "log") {
        $c->detach('view_log');
    }
    
    # Default forward
    
    $c->forward('view_group');
}


sub groups_branch4 :Path('/groups') :Args(4) {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $action2 ) = @_;
    
    if ( ($action1 eq "gallery") && ($action2 eq "add_image") ) {
        $c->detach('add_image');
    }

    if ( ($action1 eq "answers") && ($action2 eq "add_new_question") ) {
        $c->detach('add_new_group_question');
    }

    if ( ($action1 eq "answers") && ($action2 eq "add_new_answer") ) {
        $c->detach('add_new_group_answer');
    }
    
    if ( ($action1 eq "answers") && ($action2 =~ /(\d+)/) ) {
	$c->detach('display_group_question');
    }
        
    
    if ($action1 eq "images") {
        $c->detach('view_image');
    }
    
    if ($action1 eq "comment") {
	$c->detach('view_individual_group_comment');
    }
    
    if ($action1 eq "reply") {
	$c->detach('view_individual_group_reply');
    }        
    
    
    # Default forward
    
    $c->forward('view_group');
}


sub groups_branch5 :Path('/groups') :Args(5) {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $action2, $action3) = @_;

    if ( ($action1 eq "images") && ($action3 eq "add_comment") ) {
        $c->detach('add_comment_image');
    }

    if ( ($action1 eq "images") && ($action3 eq "update_image") ) {
        $c->detach('update_image');
    }

    if ( ($action1 eq "images") && ($action3 eq "delete") ) {
        $c->detach('delete_image');
    }
    
    
    if ( ($action1 eq "answers") && ($action3 eq "subscribe") ) {
        $c->detach('subscribe_group_question');
    }

    if ( ($action1 eq "answers") && ($action3 eq "unsubscribe") ) {
        $c->detach('unsubscribe_group_question');
    }

    # Admin Maintenance Stuff
    
    if ($action1 eq "admin_maintenance") {
        $c->detach('admin_maintenance');
    }
    

    # Default forward
    
    $c->forward('view_group');
}




########## Join Requests

sub join_request :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $body;
    my $Email;
    my $UserID;

    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    } else {
        $c->stash->{error_message} = "You must be logged in to make a Group join request.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }

    # Figure out where the request goes
    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    my $GroupName = $Group->name;
    
    
    my $Request = $c->model("DB::GroupJoinRequests")->create({
        group_id        => $GroupID,
        user_id         => $UserID,
        createdate      => undef,        
    });

    my $RequestorName = $Request->user_id->username; 

      # Now send all admins an e-mail, and notification


    my $Admins = WorldOfAnime::Controller::DAO_Groups::FetchAdmins( $c, $GroupID );

    while (my $a = $Admins->next) {
        my $AdminID    = $a->user_id->id;
        my $AdminName  = $a->user_id->username;
        my $AdminEmail = $a->user_id->email;
        
	$body = <<EndOfBody;
Dear $AdminName,

$RequestorName has requested to join the group $GroupName at World of Anime!  Since you are an Admin of this group, you can decide whether to accept or reject their request.

If you would like to decide to accept or reject this request, please go to http://www.worldofanime.com/groups/$GroupID/$pretty_url/join_requests
EndOfBody
    
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $AdminEmail, 1, $body, 'New Group Join Request.');
        WorldOfAnime::Controller::Notifications::AddNotification($c, $AdminID, "<a href=\"/profile/" . $RequestorName . "\">" . $RequestorName . "</a> has requested to join the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 27);
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserJoinRequests( $c, $AdminID );
    }

    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $RequestorName . "\">" . $RequestorName . "</a> has made a group join request";
    
    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $UserID,
	action_id => 15,
	action_object => $GroupID,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    &LogEvent($c, $GroupID, "$RequestorName has requested to join group", 5);
    WorldOfAnime::Controller::DAO_Groups::CleanupGroupJoinRequests( $c, $GroupID );
    WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $UserID );
        
    $c->response->redirect("/groups/$GroupID/$pretty_url");
}


sub join_requests :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $UserID;
    
    my $message = "This group currently has no join requests";
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view Group Join requests.");
    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });    


    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }
    
    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    my $GroupJoinRequestsHTML;

    my $JoinRequests = $c->model("DB::GroupJoinRequests")->search({
        group_id => $GroupID,
    });

    if ($JoinRequests->count) {
	$message = "The following people have requested to join this group";
	while (my $request = $JoinRequests->next) {
				my $username = $request->user_id->username;
				
				my $p = $c->model('Users::UserProfile');
				$p->get_profile_image( $c, $request->user_id->id );
				my $profile_image_id = $p->profile_image_id;
						
				my $i = $c->model('Images::Image');
				$i->build($c, $profile_image_id);
				my $profile_image_url = $i->thumb_url;
	
				my $points   = $request->user_id->points;
				my $join_date    = $request->user_id->confirmdate;
				my $request_date = $request->createdate;
                                my $displayJoinDate   = WorldOfAnime::Controller::Root::PrepareDate($join_date, 1, $tz);
				my $displayRequestDate   = WorldOfAnime::Controller::Root::PrepareDate($request_date, 1, $tz);
	
				my $image_gallery_link;
				$image_gallery_link = "<span class=\"top_user_profile_link\"><a href=\"/profile/$username/gallery\">Image Gallery</a></span><br />\n";

				$GroupJoinRequestsHTML .= "<div class=\"top_user_profile_box\" class=\"req_" . $request->user_id->id . "\">\n";
				$GroupJoinRequestsHTML .= "<table border=\"0\">\n";
				$GroupJoinRequestsHTML .= "	<tr>\n";
				$GroupJoinRequestsHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
				$GroupJoinRequestsHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a>";
				$GroupJoinRequestsHTML .= "		</td>\n";
				$GroupJoinRequestsHTML .= "		<td valign=\"top\" width=\"380\">\n";
				$GroupJoinRequestsHTML .= "			<span class=\"top_user_profile_name\"><a href=\"/profile/$username\">$username</a></span><br />\n";
				$GroupJoinRequestsHTML .= "			<span class=\"top_user_profile_points\">+$points points</span>\n";
				$GroupJoinRequestsHTML .= "		</td>\n";
				$GroupJoinRequestsHTML .= "		<td valign=\"top\">\n";
				$GroupJoinRequestsHTML .= "			<span class=\"top_user_profile_link\"><a href=\"/profile/$username\">Profile</a></span><br />\n";
			        $GroupJoinRequestsHTML .= "			$image_gallery_link";
				$GroupJoinRequestsHTML .= "			<span class=\"top_user_profile_link\"><a href=\"/blogs/$username\">Blog</a></span><br />\n";
				$GroupJoinRequestsHTML .= "		</td>\n";
				$GroupJoinRequestsHTML .= "	</tr>\n";
				$GroupJoinRequestsHTML .= "	<tr>\n";
				$GroupJoinRequestsHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Joined $displayJoinDate</span><br />\n";
				$GroupJoinRequestsHTML .= "                                               <span class=\"top_user_profile_date\">Requested to join group on $displayRequestDate</span>\n";				
				$GroupJoinRequestsHTML .= "<span style=\"float: right\"><a href=\"#\" class=\"friend-accept\" id=\"" . $request->user_id->id . "\"><font color=\"green\">accept</font></a> ";
				$GroupJoinRequestsHTML .= "<a href=\"#\" class=\"friend-reject\" id=\"" . $request->user_id->id . "\"><font color=\"red\">reject</font></a></span></td>\n";
				$GroupJoinRequestsHTML .= "	</tr>\n";
				$GroupJoinRequestsHTML .= "</table>\n";
				$GroupJoinRequestsHTML .= "</div>\n\n";
				$GroupJoinRequestsHTML .= "<p />\n";
	}
    }


    my $jquery = <<EndOfHTML;
<script type="text/javascript">
    \$(function() {
       \$('.friend-reject').click( function(e) {
	    var id = \$(this).attr('id');
	    if ( confirm("Are you sure you want to reject this join request?") ) {
		
		var data = 'req='  + id;

		// getting height and width of the message box
		var height = \$('#popuup_reject_div').height();
		var width = \$('#popuup_reject_div').width();
		// calculating offset for displaying popup message
		leftVal = e.pageX-(width/2)+"px";
		topVal = e.pageY-(height/2)+"px";
		// show the popup message and hide with fading effect
		\$('#popuup_reject_div').css({ left:leftVal,top:topVal }).show().fadeOut(3000);
		
	        \$.ajax({
		    url: "/groups/$GroupID/$pretty_url/reject",
		    type: "GET",
		    data: data,
                    cache: false
                });
	    
		\$('.req_' + id).remove();
	    }
            return false;
	});
    });


    \$(function() {
       \$('.friend-accept').click( function(e) {
	    var id = \$(this).attr('id');
	    if ( confirm("Are you sure you want to accept this join request?") ) {
	    
		var data = 'req='  + id;

		// getting height and width of the message box
		var height = \$('#popuup_accept_div').height();
		var width = \$('#popuup_accept_div').width();
		// calculating offset for displaying popup message
		leftVal = e.pageX-(width/2)+"px";
		topVal = e.pageY-(height/2)+"px";
		// show the popup message and hide with fading effect
		\$('#popuup_accept_div').css({ left:leftVal,top:topVal }).show().fadeOut(3000);

		
	        \$.ajax({
		    url: "/groups/$GroupID/$pretty_url/accept",
		    type: "GET",
		    data: data,
                    cache: false
                });
		
		\$('.req_' + id).remove();
	    }
            return false;
	});
    });
</script>
EndOfHTML

    $c->stash->{message} = $message;
    $c->stash->{jquery} = $jquery;
    $c->stash->{JoinRequests} = $GroupJoinRequestsHTML;
    $c->stash->{IsOwner}      = $IsOwner;
    $c->stash->{IsAdmin}      = $IsAdmin;
    $c->stash->{IsMember}     = $IsMember;    
    $c->stash->{group}        = $Group;    
    $c->stash->{template} = 'groups/join_requests.tt2';
}


sub reject_join_request :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $body;

    my $UserID = $c->req->param('req');

    # Figure out the group
    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });

    my $GroupName = $Group->name;

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $UserID );
    my $username = $u->{'username'};
    my $email    = $u->{'email'};

    my $HTMLAdminUsername = $username;
    $HTMLAdminUsername =~ s/ /%20/g;
    
    # Try to delete the request from GroupJoinRequests

    my $Request = $c->model("DB::GroupJoinRequests")->search({
	-and => [
	    group_id => $GroupID,
	    user_id => $UserID,
	],
    });

    if ($Request->count) {
        $Request->delete;
    }
    
    # Do we want to contact anyone?

    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    
    $body = <<EndOfBody;
I'm sorry to say that your request to join $GroupName has been rejected.

To see your profile, go to http://www.worldofanime.com/profile/$HTMLUsername
EndOfBody

	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $email, 1, $body, 'Group join request has been rejected.');
		
	### Create Notification
 
	WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "Your request to join <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a> has been rejected.", 11);
        
        
        # Now create notification for all the admins of the group
        
        my $Admins = WorldOfAnime::Controller::DAO_Groups::FetchAdmins( $c, $GroupID );

        while (my $a = $Admins->next) {
            my $AdminID    = $a->user_id->id;
            my $AdminName  = $a->user_id->username;
            my $AdminEmail = $a->user_id->email;
        
            WorldOfAnime::Controller::Notifications::AddNotification($c, $AdminID, "<a href=\"/profile/$username\">$HTMLUsername</a>'s request to join <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a> has been rejected.", 11);
            WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserJoinRequests( $c, $AdminID, $GroupID );
        }
    
        &LogEvent($c, $GroupID, "$HTMLUsername was rejected from joining group by $HTMLAdminUsername", 7);
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupJoinRequests( $c, $GroupID );
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $UserID );
}



sub accept_join_request :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $body;
    my $Email;

    my $UserID = $c->req->param('req');
    

    # Figure out the group
    
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });

    my $GroupName = $Group->name;

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $UserID );
    my $username = $u->{'username'};
    my $email    = $u->{'email'};

    my $HTMLAdminUsername = $username;
    $HTMLAdminUsername =~ s/ /%20/g;
    
    # Try to delete the request from GroupJoinRequests

    my $Request = $c->model("DB::GroupJoinRequests")->search({
	-and => [
	    group_id => $GroupID,
	    user_id => $UserID,
	],
    });

    if ($Request->count) {
        $Request->delete;
    }


    # Now, add them to Group Users
    
    my $NewMember = $c->model("DB::GroupUsers")->create({
        group_id   => $GroupID,
        user_id    => $UserID,
        is_admin   => 0,
        modifydate => undef,
        createdate => undef,
    });
    
    
    
    # Do we want to contact anyone?
    
    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    
    $body = <<EndOfBody;
Great news!  Your request to join $GroupName has been accepted!  Welcome to the group!

To start participating in this group, go to http://www.worldofanime.com/groups/$GroupID/$pretty_url
EndOfBody
    
        WorldOfAnime::Controller::DAO_Email::SendEmail($c, $email, 1, $body, 'Group join request has been accepted.');
		
	### Create Notification
 
	WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "Your request to join <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a> has been accepted.", 10);
        
        # Now create notification for all the admins of the group
        
        my %Notified; # To prevent multiple notifications

        my $Admins = WorldOfAnime::Controller::DAO_Groups::FetchAdmins( $c, $GroupID );
        
    while (my $a = $Admins->next) {
        my $AdminID    = $a->user_id->id;
        my $AdminName  = $a->user_id->username;
        my $AdminEmail = $a->user_id->email;
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $AdminID, "<a href=\"/profile/$username\">$HTMLUsername</a>'s request to join <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a> has been accepted.", 10);
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserJoinRequests( $c, $AdminID, $GroupID );
    }
    

    # Now, notify all the members of the group that a new person has joined
    
    my $Members = $c->model('DB::GroupUsers')->search({
        group_id => $GroupID,
    });
    
    while (my $m = $Members->next) {
        my $notify_id = $m->user_id->id;
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $notify_id, "<a href=\"/profile/$username\">$HTMLUsername</a> has joined the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>.", 23);
        
        next if ($Notified{$notify_id});
        
        # If they want an e-mail, send them one
        
        my $body = <<EndOfHTML;
$username has just joined the group $GroupName!

You can go to this group here: http://www.worldofanime.com/groups/$GroupID/$pretty_url

To stop receiving e-mail notifications when a new member joins a group you are a member of, log on to http://www.worldofanime.com/, edit your profile, and uncheck When a new member joins under Group Notifications
EndOfHTML
        
	if ($m->user_id->user_profiles->notify_group_new_member) {
	    my $email_address = $m->user_id->email;
	    
	    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $email_address, 1, $body, 'New Member has joined one of your groups.');

        }
    }
        
        
    &LogEvent($c, $GroupID, "$HTMLUsername was accepted into the group by $HTMLAdminUsername", 6);
    WorldOfAnime::Controller::DAO_Groups::CleanupGroupJoinRequests( $c, $GroupID );
    WorldOfAnime::Controller::DAO_Groups::CleanGroupMembers( $c, $GroupID );
    WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $UserID );
}


sub invite_user :Local {
    my ( $self, $c ) = @_;
    
    my $UserID; # User ID of inviter
    my $InviteeID; # User ID of invitee
    my $InviteeName; # Username of invitee

    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $User = $c->model('DB::Users')->find({
        id => $UserID,
    });
    
    my $username = $User->username;
    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    
    
    my $group_id = $c->req->params->{'group_id'};
    my $user = $c->req->params->{'user'};
    
    
    my $Group = $c->model('DB::Groups')->find({
        id => $group_id,
    });
    
    my $GroupName  = $Group->name;
    my $pretty_url = $Group->pretty_url;
    
    
    # Figure out this users ID
    
    my $Invitee = WorldOfAnime::Controller::DAO_Users::GetUserByUsername($c, $user);
    

    if ($Invitee) {
        $InviteeID = $Invitee->id;
        $InviteeName = $Invitee->username;

        # end if user is already a member
    
        my $AlreadyMember = $c->model('DB::GroupUsers')->search({
            -and => [
                group_id => $group_id,
                user_id => $InviteeID,
            ],
        });
        
        if ($AlreadyMember->count) { detach(); }
        
        
        # end if this invitation already exists
        
        $c->model('DB::GroupInvites')->create({
            group_id => $group_id,
            user_id => $InviteeID,
            invited_by => $UserID,
            createdate => undef,
        },{
            key => 'invitation'
          });
        
        # Send invitee a notification
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $InviteeID, "<a href=\"/profile/$username\">$HTMLUsername</a> has invited you to join the group <a href=\"/groups/$group_id/$pretty_url\">$GroupName</a>", 20);
        
        # And an e-mail
        
        my $body = <<EndOfHTML;
Dear $InviteeName,

$username has invited you to join the group $GroupName on World of Anime!

To accept or reject this group invite, you can go here: http://www.worldofanime.com/groups/$group_id/$pretty_url
EndOfHTML

	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $Invitee->email, 1, $body, "$username has invited you to join a Group");

    }

    if ($InviteeName) {
        &LogEvent($c, $group_id, "$HTMLUsername invited $InviteeName to join the group", 2);
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $group_id, $UserID );
    }
}



sub accept_invite :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $UserID;
    
    # Info about the user
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $User = $c->model('DB::Users')->find({
        id => $UserID,
    });

    my $username = $User->username;
    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    

    # Info about the group
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    my $GroupName  = $Group->name;    

    # Get all of this person's invites
    
    my $Invites = $c->model('DB::GroupInvites')->search({
        -and => [
            group_id => $GroupID,
            user_id => $UserID,
        ],
    });
    
    # Notify all the inviters that this person has accepted
    my %Notified; # Use this to prevent people from being notified twice

    
    while (my $i = $Invites->next) {
        my $notify_id = $i->invited_by->id;
        WorldOfAnime::Controller::Notifications::AddNotification($c, $notify_id, "<a href=\"/profile/$username\">$HTMLUsername</a> has accepted your invitation to join the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 21);
        $Notified{$notify_id} = 1;
        
        # We can delete the invite now, too
        $i->delete;
    }
    
    # Now, notify all the members of the group that a new person has joined
    
    my $Members = $c->model('DB::GroupUsers')->search({
        group_id => $GroupID,
    });
    
    while (my $m = $Members->next) {
        my $notify_id = $m->user_id->id;
        next if ($Notified{$notify_id});
        
        # If they want an e-mail, send them one
        
        my $body = <<EndOfHTML;
$username has just joined the group $GroupName!

You can go to this group here: http://www.worldofanime.com/groups/$GroupID/$pretty_url

To stop receiving e-mail notifications when a new member joins a group you are a member of, log on to http://www.worldofanime.com/, edit your profile, and uncheck When a new member joins under Group Notifications
EndOfHTML
        
	if ($m->user_id->user_profiles->notify_group_new_member) {
	    my $email_address = $m->user_id->email;
	    
	    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $email_address, 1, $body, "New Member has joined one of your groups.");

        }
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $notify_id, "<a href=\"/profile/$username\">$HTMLUsername</a> has joined the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 23);
    }
    

    # Now, do the actual join
    
    my $NewMember = $c->model('DB::GroupUsers')->create({
        group_id => $GroupID,
        user_id => $UserID,
        is_admin => 0,
        modifydate => undef,
        createdate => undef,
    });

    &LogEvent($c, $GroupID, "$username accepted their request to join the group", 3);
    WorldOfAnime::Controller::DAO_Groups::CleanGroupMembers( $c, $GroupID );
    WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $UserID );

    $c->response->redirect("/groups/$GroupID/$pretty_url");
}


sub decline_invite :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $UserID;
    
    # Info about the user
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $User = $c->model('DB::Users')->find({
        id => $UserID,
    });

    my $username = $User->username;
    my $HTMLUsername = $username;
    $HTMLUsername =~ s/ /%20/g;
    

    # Info about the group
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    my $GroupName  = $Group->name;    

    # Get all of this person's invites
    
    my $Invites = $c->model('DB::GroupInvites')->search({
        -and => [
            group_id => $GroupID,
            user_id => $UserID,
        ],
    });
    
    # Notify all the inviters that this person has accepted
    my %Notified; # Use this to prevent people from being notified twice

    
    while (my $i = $Invites->next) {
        my $notify_id = $i->invited_by->id;
        WorldOfAnime::Controller::Notifications::AddNotification($c, $notify_id, "<a href=\"/profile/$username\">$HTMLUsername</a> has rejected your invitation to join the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>", 22);
        $Notified{$notify_id} = 1;
        
        # We can delete the invite now, too
        $i->delete;
    }


    &LogEvent($c, $GroupID, "$username declined their request to join the group", 4);
    WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $UserID );
    
    $c->response->redirect("/groups/$GroupID/$pretty_url");    
}


sub member_maintenance :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $MembersHTML;
    my $UserID;

    my $cpage = $c->req->params->{'cpage'} || 1;
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });


    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    
    
    # Get members HTML
    
    my $Members = $c->model('DB::GroupUsers')->search({
        group_id => $GroupID,
    },{
        order_by => 'modifydate ASC',
      });
    
    my %seen;
    while (my $member = $Members->next) {
        my $member_id = $member->user_id->id;
        
	next if ($seen{$member_id});
	$seen{$member_id} = 1;
	my $username = $member->user_id->username;

	my $p = $c->model('Users::UserProfile');
	$p->get_profile_image( $c, $member->user_id->id );
	my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
			
	my $i = $c->model('Images::Image');
	$i->build($c, $profile_image_id);
	my $profile_image_url = $i->thumb_url;	

	my $mult    = ($height / 80);

	my $new_height = int( ($height/$mult) / 1.5 );
	my $new_width  = int( ($width/$mult) /1.5);
        
	my $join_date = $member->createdate;
	my $displayJoinDate = WorldOfAnime::Controller::Root::PrepareDate($join_date, 1);

	$MembersHTML .= "<div class=\"top_user_profile_box\">\n";
	$MembersHTML .= "<table border=\"0\">\n";
	$MembersHTML .= "	<tr>\n";
	$MembersHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
	$MembersHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" height=\"$new_height\" width=\"$new_width\"></a>";
	$MembersHTML .= "		</td>\n";
	$MembersHTML .= "		<td valign=\"top\"><span class=\"top_user_profile_date\">$username has been a member since $displayJoinDate</span></td>\n";
	$MembersHTML .= "	</tr>\n";
	$MembersHTML .= "	<tr>\n";
        $MembersHTML .= "               <td valign=\"bottom\">";

        # Build links for user actions
        
        if ($member_id == $Group->created_by_user_id) {
            $MembersHTML .= "$username is the creator of this group";
        } else {
    
            if ($member->is_admin) {
                $MembersHTML .= "<a href=\"/groups/$GroupID/$pretty_url/admin_maintenance/remove_admin/$member_id\"><font color=\"red\">Remove Admin Status</font></a>";
            } else {
                $MembersHTML .= "<a href=\"/groups/$GroupID/$pretty_url/admin_maintenance/make_admin/$member_id\"><font color=\"green\">Make an Admin</font></a>";
            }
            $MembersHTML .= " | ";
            $MembersHTML .= "<a href=\"/groups/$GroupID/$pretty_url/admin_maintenance/remove_member/$member_id\"><font color=\"red\">Remove From Group</font></a>";
        }
            
        $MembersHTML .= "               </td>\n";
	$MembersHTML .= "	</tr>\n";
	$MembersHTML .= "</table>\n";
	$MembersHTML .= "</div>\n\n";
	$MembersHTML .= "<p />\n";
    }

    
        

    my $jquery = <<EndOfHTML;
<script type="text/javascript">
    \$(function() {
       \$('.delete-comment').click( function() {
	    var id = \$(this).attr('id');
            var group_id = \$(this).attr('group_id');
            var type = \$(this).attr('type');
	    if ( confirm("Are you sure you want to permanently delete this comment?") ) {
		
		var data = 'comment='  + id + '&group_id=' + group_id + '&type=' + type;
		
	        \$.ajax({
		    url: "/groups/comment/delete",
		    type: "GET",
		    data: data,
                    cache: false
                });
	    
		\$('.comment_' + id).remove();
	    }
            return false;
	});
    });
    
    \$(function() {    
	\$('.removable_button').submit(function() {
            \$('.removable').remove();
	});
    });    
</script>    
EndOfHTML

    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff   
    
    $c->stash->{IsOwner}      = $IsOwner;
    $c->stash->{IsAdmin}      = $IsAdmin;
    $c->stash->{IsMember}     = $IsMember;
    $c->stash->{IsPrivate}    = $Group->is_private;
    $c->stash->{MembersHTML}  = $MembersHTML;
    $c->stash->{group}        = $Group;
    $c->stash->{current_uri}  = $current_uri;
    $c->stash->{jquery}       = $jquery;    
    $c->stash->{template} = 'groups/member_maintenance.tt2';
}



sub view_log :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action ) = @_;
    my $UserID;

    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });


    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
    
                # Maybe their have been some invites?
            my $Invites = $c->model('DB::GroupInvites')->search({
                group_id => $GroupID,
                user_id => $UserID,
            });
            
            if ($Invites) {
                $c->stash->{Invites} = $Invites;
            }
    

    my $page = $c->req->params->{'page'} || 1;
    
    my $Entries = $c->model("DB::GroupLogs")->search({
        group_id => $GroupID,
    },{
      page      => "$page",
      rows      => 50,
      order_by  => 'create_date DESC',
      });
    
    my $pager = $Entries->pager();

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff

    $c->stash->{pager}    = $pager;    
    $c->stash->{Entries}  = $Entries;    
    $c->stash->{group}    = $Group;
    $c->stash->{IsAdmin}  = $IsAdmin;
    $c->stash->{template} = 'groups/log.tt2';
}


sub admin_maintenance :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $action2, $action3 ) = @_;
    my $UserID;

    # Make sure this person really is an admin
    
    if ($c->user_exists() ) {
        $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }

    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $UserID, $GroupID );
        
    unless ($IsAdmin) {
        $c->stash->{error_message} = "Come on, seriously.  You've got to be an admin of this group to do whatever you just tried to do.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }

    # Info about the group
    my $Group = $c->model('DB::Groups')->find({
        id => $GroupID,
    });
    
    my $GroupName  = $Group->name;
    my $GroupOwner = $Group->group_creator->username;
    
    my $ActionMemberName;
    my $ActionMember;
    my $ActionMemberSearch = $c->model('DB::GroupUsers')->search({
        -and => [
            group_id => $GroupID,
            user_id  => $action3,
        ],
    });
    
    if ($ActionMemberSearch->count) {
        $ActionMember = $ActionMemberSearch->next;
        $ActionMemberName = $ActionMember->user_id->username;
    }
    

    if ($action2 eq "remove_admin") {
        $ActionMember->update({
            is_admin => 0,
        });
        
        # Send notification
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $action3, "Your admin status has been removed from the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>.", 25);
        
        &LogEvent($c, $GroupID, "$GroupOwner removed admin status from $ActionMemberName", 9);
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $action3 );

    }

    if ($action2 eq "make_admin") {
        $ActionMember->update({
            is_admin => 1,
        });
        
        # Send notification
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $action3, "You have been made an admin of the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>.", 24);
        
        &LogEvent($c, $GroupID, "$GroupOwner made $ActionMemberName an admin", 8);
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $action3 );
    }
    
    if ($action2 eq "remove_member") {
        $ActionMember->delete;
        
        WorldOfAnime::Controller::Notifications::AddNotification($c, $action3, "You have been removed from the group <a href=\"/groups/$GroupID/$pretty_url\">$GroupName</a>.", 26);
        
        &LogEvent($c, $GroupID, "$GroupOwner removed $ActionMemberName from the group", 10);
        WorldOfAnime::Controller::DAO_Groups::CleanGroupMembers( $c, $GroupID );
        WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $GroupID, $action3 );
    }    
    
    
    
    $c->response->redirect("/groups/$GroupID/$pretty_url/member_maintenance");    
}


sub leave_group :Path('/groups/leave') :Args(0) {
    my ( $self, $c ) = @_;
    my $user_id;

    if ($c->user_exists() ) {
        $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    }
    
    my $group_id = $c->req->params->{'group_id'};

    	
    my $g =$c->model('Groups::Group');
    $g->build( $c, $group_id );
    my $group_name = $g->name;
    my $pretty_url = $g->pretty_url;
    
    # Find out this users status
    
    my ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest) = WorldOfAnime::Controller::DAO_Groups::GetUserGroupStatus( $c, $user_id, $group_id );
    
    if (( $IsMember) && !($IsOwner) ) {  # For now we can not allow owners to leave their own group
	my $Member = $c->model('DB::GroupUsers')->search({
	    -and => [
                group_id => $group_id,
	        user_id  => $user_id,
	    ],
	});
	
	$Member->delete;
	$c->cache->remove("woa:user_groups:$user_id");
	WorldOfAnime::Controller::DAO_Groups::CleanGroupMembers( $c, $group_id );
	WorldOfAnime::Controller::DAO_Groups::CleanupGroupUserStatus( $c, $group_id, $user_id );
	
	my $p = $c->model('Users::UserProfile');
	$p->build( $c, $user_id );
	my $username = $p->username;
	
	&LogEvent($c, $group_id, "$username has left the group", 14);

	# For every member of the group...
	# Do they want to know about it?
    
	my $members;
	my $members_json = WorldOfAnime::Controller::DAO_Groups::GetGroupMembers_JSON( $c, $group_id );
	if ($members_json) { $members = from_json( $members_json ); }
    
	foreach my $m (@{ $members}) {
	    
	    my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $m->{id} );
    
	    ### Create Notification
	
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $m->{id}, "<a href=\"/profile/" . $username . "\">" . $username . "</a> has left the group <a href=\"/groups/$group_id/$pretty_url\">$group_name</a>", 37);
    
	}

    }
    
    $c->response->body("done");
}


sub subscribe_group_question :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $question_id, $action3) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Get this question
    
    my $QA = $c->model('DB::QAQuestions')->find({
        id      => $question_id,
    });
    
    my $user_id = $QA->asked_by_user->id;
    my $subject = $QA->subject;
    
    
    # Get subscriber
    
    my $User = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $User->username;
    
    # Add subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::QASubscriptions')->create({
	    question_id => $question_id,
	    user_id => $viewer_id,
	    modify_date => undef,
	    create_date => undef,
        });
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has subscribed to your question titled <a href=\"/groups/$GroupID/$pretty_url/answers/$question_id\">$subject</a>.", 8);
    }
    
    $c->response->redirect("/groups/$GroupID/$pretty_url/answers/$question_id");    
}


sub unsubscribe_group_question :Local {
    my ( $self, $c, $GroupID, $pretty_url, $action1, $question_id, $action3) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Get this question
    
    my $QA = $c->model('DB::QAQuestions')->find({
        id      => $question_id,
    });
    
    my $user_id = $QA->asked_by_user->id;
    my $subject = $QA->subject;
    
    
    # Get subscriber
    
    my $User = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $User->username;
    
    # Remove subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::QASubscriptions')->find({
	    question_id => $question_id,
	    user_id => $viewer_id,
        });
	
	if ($Sub) {
	    $Sub->delete;
	    
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has unsubscribed from your question titled <a href=\"/groups/$GroupID/$pretty_url/answers/$question_id\">$subject</a>.", 13);
	}
    }
    
    $c->response->redirect("/groups/$GroupID/$pretty_url/answers/$question_id");    
}




sub LogEvent : Local {
    my ( $c, $group_id, $log, $type ) = @_;
    
    ### Log Types
    # 1 = create group
    # 2 = invited user
    # 3 = user accepted invitation
    # 4 = user rejected invitation
    # 5 = user requested to join
    # 6 = request was approved
    # 7 = request was denied
    # 8 = admin status given
    # 9 = admin status removed
    # 10 = user removed from group
    # 11 = group edited
    # 12 = comment deleted
    # 13 = image deleted
    # 14 = user left group on their own
    
    $c->model('DB::GroupLogs')->create({
	group_id => $group_id,
        log_type => $type,
	log => $log,
	create_date => undef,
    });

    return 1;
}


1;
