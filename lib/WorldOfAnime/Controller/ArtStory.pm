package WorldOfAnime::Controller::ArtStory;
use Moose;
use namespace::autoclean;
use JSON;
use List::MoreUtils qw(uniq);

BEGIN {extends 'Catalyst::Controller'; }


sub index :Path('/artist/fiction') :Args(0) {
    my ( $self, $c ) = @_;
    
    $c->stash->{images_approved} = 1;
    $c->stash->{template} = 'art/main_story.tt2';
}


sub howto :Path('/artist/fiction/howto') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{images_approved} = 1;
    $c->stash->{template} = 'art/fiction_howto.tt2';
}


sub browse_fiction_by_title :Path('/artist/fiction/browse_fiction_by_title') {
    my ( $self, $c ) = @_;
    
    my ($StoryCount, $StoryID) = WorldOfAnime::Controller::DAO_ArtStory::GetStoryCount( $c );

    $c->stash->{images_approved} = 1;
    $c->stash->{story_count} = $StoryCount;
    $c->stash->{story_id}    = $StoryID;
    $c->stash->{browse_type} = 'by_title';
    $c->stash->{template}    = 'art/browse_fiction.tt2';
}


sub browse_fiction_original :Path('/artist/fiction/browse_fiction_original') {
    my ( $self, $c ) = @_;
    
    my $cpage = $c->req->params->{'cpage'} || 1;
    
    my $Fiction = $c->model('DB::ArtStoryTitle')->search({
        -and => [
            db_title_id => 0,
            publish => 1,
        ],
    },{
	page     => "$cpage",
        rows      => 25,
	order_by  => 'createdate DESC',
    });
    
    my $cpager = $Fiction->pager();

    $c->stash->{images_approved} = 1;
    $c->stash->{fiction}  = $Fiction;
    $c->stash->{browse_type} = 'original';
    $c->stash->{cpager}    = $cpager;
    $c->stash->{template} = 'art/browse_fiction.tt2';
}


sub setup_add_story :Path('/artist/fiction/setup_add') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a new fan fiction.");
    
    my $RatingSelectHTML = WorldOfAnime::Controller::DAO_ArtStory::GetRatingSelectHTML( $c );
    
    $c->stash->{images_approved} = 1;
    $c->stash->{rating_select} = $RatingSelectHTML;
    $c->stash->{template}      = 'art/add_story.tt2';
}


sub add_new_story :Path('/artist/fiction/add_new_title') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a new fan fiction.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username   = $u->{'username'};    
    
    my $title           = $c->req->params->{fiction_title};
    my $rating_id       = $c->req->params->{rating};
    my $title_id        = $c->req->params->{anime_title_id} || 0;
    my $description     = $c->req->params->{description};
    my $chapter_title   = $c->req->params->{chapter_title};
    my $chapter_content = $c->req->params->{chapter_content};
    
    # Create new title
    
    my $Title = $c->model('DB::ArtStoryTitle')->create({
        started_by_user_id => $user_id,
        db_title_id        => $title_id,
        rating_id          => $rating_id,
        title              => $title,
        description        => $description,
        publish            => 1,
        modifydate         => undef,
        createdate         => undef,
    });
    
    my $story_id = $Title->id;
    
    # Create chapter 1
    
    my $Chapter = $c->model('DB::ArtStoryChapter')->create({
       story_id        => $story_id,
       user_id         => $user_id,
       chapter_num     => 1,
       chapter_title   => $chapter_title,
       chapter_content => $chapter_content,
       publish         => 1,
       modifydate      => undef,
       createdate      => undef,
    });
    
    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );
    
    my $story_title  = $s->title;
    my $pretty_title = $s->pretty_title;
    
    # Add points

    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has written ";
    $ActionDescription .= "<a href=\"/artist/fiction/view_story/$story_id/1/$pretty_title\">Chapter 1</a> of $story_title";
        
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 29, $Chapter->id);
    
    ### Add notifications to people who want it
    
    my $notification = "<a href=\"/profile/$username\">$username</a> has written <a href=\"/artist/fiction/view_story/$story_id/1/$pretty_title\">Chapter 1</a> of $story_title";
    
    # Add notification to friends
    
    my $friends;
    my $friends_json = WorldOfAnime::Controller::DAO_Friends::GetFriends_JSON( $c, $user_id );
    if ($friends_json) { $friends = from_json( $friends_json ); }
    
    WorldOfAnime::Controller::Notifications::MultiNotify( 1, $c, $notification, 34, $friends );
    
    
    # E-mail me a copy
		
    my $body = <<EndOfBody;
A new Fan Fiction called $story_title was written by $username
EndOfBody

    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, "New Fan Fiction Title");
    

    # Forward to chapter 1
    
    $c->response->redirect("/artist/fiction/view_story/$story_id/1/$pretty_title");
    $c->detach();
}


sub edit_story :Path('/artist/fiction/edit_title') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit a fan fiction.");

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username   = $u->{'username'};    

    my $chapter         = $c->req->params->{chapter};
    my $story_id        = $c->req->params->{story_id};

    ## Create title from existing story_id
    
    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );
    
    # Before allowing this, make sure $u is the owner
    
    if ($s->started_by == $user_id) {
        $s->update( $c );
    }

    my $title = $s->title;
    my $pretty_title = $s->pretty_title;
    
    $c->response->redirect("/artist/fiction/view_story/$story_id/$chapter/$pretty_title");
    $c->detach();
}


sub write_chapter :Path('/artist/fiction/write_chapter') :Args(0) {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a new chapter.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username   = $u->{'username'};
    
    my $story_id        = $c->req->params->{story_id};
    my $chapter_content = $c->req->params->{chapterContent};
    my $chapter_title   = $c->req->params->{chapterTitle};
    
    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );
    
    my $story_title  = $s->title;
    my $pretty_title = $s->pretty_title;
    
    my $chapters;
    #my $chapters_json = WorldOfAnime::Controller::DAO_ArtStory::FetchChaptersByStoryID_JSON( $c, $story_id );
    my $chapters_json = $s->chapters;
    if ($chapters_json) { $chapters = from_json( $chapters_json ); }
    
    my $chapter_num = eval { scalar @{ $chapters } };
    $chapter_num++;

    my $Chapter = $c->model('DB::ArtStoryChapter')->create({
       story_id        => $story_id,
       user_id         => $user_id,
       chapter_num     => $chapter_num,
       chapter_title   => $chapter_title,
       chapter_content => $chapter_content,
       publish         => 1,
       modifydate      => undef,
       createdate      => undef,
    });

    # Clear any info about the story from cache
    $s->clear( $c );
    
    # Add points

    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has written ";
    $ActionDescription .= "<a href=\"/artist/fiction/view_story/$story_id/$chapter_num/$pretty_title\">Chapter $chapter_num</a> of $story_title";
        
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 30, $Chapter->id);
    
    ### Add notifications to people who want it
    
    my $notification = "<a href=\"/profile/$username\">$username</a> has written <a href=\"/artist/fiction/view_story/$story_id/$chapter_num/$pretty_title\">Chapter $chapter_num</a> of $story_title";
    
    # Add notification to friends
    
    my $friends;
    my $friends_json = WorldOfAnime::Controller::DAO_Friends::GetFriends_JSON( $c, $user_id );
    if ($friends_json) { $friends = from_json( $friends_json ); }

    # Add notification to subscribers
    
    my $subscribers;
    my $subscribers_json = WorldOfAnime::Controller::DAO_ArtStory::GetSubscribers_JSON( $c, $story_id );
    if ($subscribers_json) { $subscribers = from_json( $subscribers_json ); }


    
    # E-mail me a copy
		
    my $body = <<EndOfBody;
A new Fan Fiction Chapter for $story_title was written by $username
EndOfBody

    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, "New Fan Fiction Chapter");
    
    
    $c->detach("WorldOfAnime::Controller::Notifications", "MultiNotify", [ $notification, 34, $friends, $subscribers ]);
}



sub edit_chapter :Path('/artist/fiction/edit_chapter') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit a chapter.");

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username   = $u->{'username'};    

    my $chapter_id      = $c->req->params->{chapter_id};

    ## Create chapter from existing chapter_id
    
    my $chap = $c->model('Art::StoryChapter');
    $chap->build( $c, $chapter_id );
    
    ## Create title from existing story_id

    my $story_id = $chap->story_id;
    
    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );

    my $title = $s->title;
    my $pretty_title = $s->pretty_title;

    my $chapter = $chap->chapter_num;    

    
    # Before allowing this, make sure $u is the owner
    # Note to self - when creating Collaborative Fan Fiction, we want the chapter to be editable by both the writer, and the owner of the story
    
    if ($chap->user_id == $user_id) {
        $chap->update( $c );
    }

    
    $c->response->redirect("/artist/fiction/view_story/$story_id/$chapter/$pretty_title");
    $c->detach();
}



sub check_subscription :Path('/artist/fiction/check_subscription') :Args(1) {
    my ( $self, $c, $story_id ) = @_;
    my $HTML;
    
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($UserID) {
        $c->response->body(" ");
        $c->detach();
    }
    
    if (WorldOfAnime::Controller::DAO_ArtStory::IsSubscribed( $c, $story_id, $UserID )) {
        $HTML = <<EndOfHTML;
<div id="subscription_button">
unsubscribe from this story
</div>
EndOfHTML
    } else {
        $HTML = <<EndOfHTML;
<div id="subscription_button">
subscribe to this story
</div>
EndOfHTML
    }
    
    $c->response->body($HTML);
}


sub toggle_subscription :Path('/artist/fiction/toggle_subscription') :Args(0) {
    my ( $self, $c ) = @_;

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($user_id) {
        $c->response->body(" ");
        $c->detach();
    }
    
    my $story_id        = $c->req->params->{story_id};

    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );
    
    my $title        = $s->title;
    my $pretty_title = $s->pretty_title;
    my $owner_id     = $s->started_by;
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username = $u->{'username'};
    
    if (WorldOfAnime::Controller::DAO_ArtStory::IsSubscribed( $c, $story_id, $user_id )) {
        # Unsubscribe user
        WorldOfAnime::Controller::DAO_ArtStory::Unsubscribe( $c, $story_id, $user_id );
        unless ($owner_id == $user_id) {
            WorldOfAnime::Controller::Notifications::AddNotification($c, $owner_id, "<a href=\"/profile/" . $username . "\">" . $username . "</a> has unsubscribed from your fan fiction <a href=\"/artist/fiction/view_story/$story_id/1/$pretty_title\">$title</a>.", 13);
        }        
    } else {
        # Subscribe user
        WorldOfAnime::Controller::DAO_ArtStory::Subscribe( $c, $story_id, $user_id );
        unless ($owner_id == $user_id) {
            WorldOfAnime::Controller::Notifications::AddNotification($c, $owner_id, "<a href=\"/profile/" . $username . "\">" . $username . "</a> has subscribed to your fan fiction <a href=\"/artist/fiction/view_story/$story_id/1/$pretty_title\">$title</a>.", 8);
        }
    }
    
    WorldOfAnime::Controller::DAO_ArtStory::CleanSubscribers( $c, $story_id );

    $c->response->body(" ");
    $c->detach();    
}



sub view_story :Path('/artist/fiction/view_story') :Args(3) {
    my ( $self, $c, $story_id, $chapter_num, $pretty_title ) = @_;
    my @image_ids;

    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $CommentsHTML;
    my $count = 0;
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";    
    my $get_latest_id = 1;
    
    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );
    
    my $chapters;
    my $chapters_json = $s->chapters;
    if ($chapters_json) { $chapters = from_json( $chapters_json ); }
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $s->started_by );
    
    if ($UserID == $s->started_by) {
        # This story was started by this user
        
        $c->stash->{can_edit} = 1;
        $c->stash->{can_write} = 1;
    }
    
    if ($chapter_num eq "latest") {
        # We can use this to always show the latest chapter
        
        $chapter_num = eval {  @{ $chapters } };
    }
    
    # Get this chapter id (story_id, chapter_num combo)
    my $chapter_id = WorldOfAnime::Controller::DAO_ArtStory::GetChapterID( $c, $story_id, $chapter_num );
    
    # Get the actual chapter
    my $chap = $c->model('Art::StoryChapter');
    $chap->build( $c, $chapter_id );

    my ($Comments, $latest) = WorldOfAnime::Controller::DAO_ArtStory::GetArtStoryComments( $c, $story_id, $chapter_id, 0, $get_latest_id );

    while (my $com = $Comments->next) {
        my $com_id = $com->id;
        my $comment = WorldOfAnime::Controller::DAO_ArtStory::GetArtStoryCommentCacheable( $c, $com_id);
        
        my $user_id    = $comment->{'user_id'};
        my $username   = $comment->{'username'};
        my $createdate = $comment->{'createdate'};
        my $content    = $comment->{'comment'};
        $content =~ s/\n/<br>/g;

        my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $user_id );
        my $profile_image_id = $p->profile_image_id;
	   push (@image_ids, $profile_image_id);
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;
        
        my $postDate = WorldOfAnime::Controller::Root::PrepareDate($createdate, 1, $tz);
        
        $CommentsHTML .= "<div class=\"comment\">\n";
        $CommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\"></a>\n";
        $CommentsHTML .= "<p class=\"article\">" . $content . "</p>\n";
        $CommentsHTML .= "<br clear=\"all\">\n";
        $CommentsHTML .= "<h2>Submitted by <a href=\"/profile/$username\">$username</a> on $postDate</h2><br />";
        $CommentsHTML .= "</div>\n";
        
        $count++;
    }
    

    my $num_chapters = eval {  @{ $chapters } };
    
    @image_ids = uniq(@image_ids);
        
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids ) &&
                          WorldOfAnime::Controller::DAO_Images::IsExternalLinksApprovedPreRender( $c, $CommentsHTML );
    $c->stash->{story}        = $s;
    $c->stash->{chapter}      = $chap;
    $c->stash->{chapters}     = $chapters;
    $c->stash->{user}         = $u;
    $c->stash->{chapter_num}  = $chapter_num;
    $c->stash->{chapter_id}   = $chapter_id;
    $c->stash->{num_chapters} = $num_chapters;
    $c->stash->{pretty_title} = $pretty_title;
    $c->stash->{comments_html} = $CommentsHTML;
    $c->stash->{num_comments} = $count;
    $c->stash->{latest} = $latest;    
    $c->stash->{template}     = 'art/view_story.tt2';
}


##### AJAX methods

sub add_comment :Path('/artist/fiction/ajax/add_comment') :Args(2) {
    my ( $self, $c, $story_id, $chapter_id ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a comment.");
    
    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );
    
    my $title = $s->title;
    my $started_by = $s->started_by;
    my $pretty_title = $s->pretty_title;

    # Get this chapter num (given a chapter_id)
    my $chapter_num = WorldOfAnime::Controller::DAO_ArtStory::GetChapterNum( $c, $chapter_id );
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $user_id  = $u->{'id'};
    my $username = $u->{'username'};
    
    my $comment = $c->req->params->{comment};
    
    my $nc = $c->model('DB::ArtStoryComments')->create({
        art_story_id => $story_id,
        chapter_id => $chapter_id,
        user_id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
        comment => $comment,
        modifydate => undef,
        createdate => undef,
    });

    # Create Action
    
    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has commented on <a href=\"/artist/fiction/view_story/$story_id/$chapter_num/$pretty_title\">chapter $chapter_num</a> of ";
    $ActionDescription .= "<a href=\"/artist/fiction/view_story/$story_id/1/$pretty_title\">$title</a>";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 31, $chapter_id);    

    # Add notification to owner and subscriber
    
    my $notification = $ActionDescription;
    
    my $subscribers;
    my $subscribers_json = WorldOfAnime::Controller::DAO_ArtStory::GetSubscribers_JSON( $c, $story_id );
    if ($subscribers_json) {
        $subscribers = from_json( $subscribers_json );
    }
    push (@{ $subscribers}, { 'user_id' => "$started_by" });  # Add original writer to the notification list    

    WorldOfAnime::Controller::Notifications::MultiNotify( $self, $c, $notification, 1, 0, $subscribers );
    #$c->detach("WorldOfAnime::Controller::Notifications", "MultiNotify", [ $notification, 1, 0, $subscribers ]);
    
    $c->response->body("ok");
}


sub load_comments :Path('/artist/fiction/ajax/load_comments') :Args(3) {
    my ( $self, $c, $story_id, $chapter_id, $latest ) = @_;
    my $CommentsHTML;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    my $Comments = WorldOfAnime::Controller::DAO_ArtStory::GetArtStoryComments( $c, $story_id, $chapter_id, $latest);
    
    while (my $com = $Comments->next) {
        my $com_id = $com->id;
        my $comment = WorldOfAnime::Controller::DAO_ArtStory::GetArtStoryCommentCacheable( $c, $com_id);

        my $user_id    = $comment->{'user_id'};        
        my $username   = $comment->{'username'};
        my $createdate = $comment->{'createdate'};
        my $content    = $comment->{'comment'};
        $content =~ s/\n/<br>/g;
        
        my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $user_id );
        my $profile_image_id = $p->profile_image_id;
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;        
        
        my $postDate = WorldOfAnime::Controller::Root::PrepareDate($createdate, 1, $tz);        
        
        $CommentsHTML .= "<div class=\"comment\">\n";
        $CommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\"></a>\n";
        $CommentsHTML .= "<p class=\"article\">" . $content . "</p>\n";
        $CommentsHTML .= "<br clear=\"all\">\n";
        $CommentsHTML .= "<h2>Submitted by <a href=\"/profile/$username\">$username</a> on $postDate</h2><br />";
        $CommentsHTML .= "</div>\n";
    }
    
    $c->response->body($CommentsHTML);
}


sub setup_edit_title :Path('/artist/fiction/ajax/setup_edit_title') :Args(1) {
    my ( $self, $c, $story_id ) = @_;
    my $EditHTML;
    my $AnimeSelectBox;
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $user_id  = $u->{'id'};

    my $s = $c->model('Art::Story');
    $s->build( $c, $story_id );
    
    my $story_title    = $s->title;
    my $description    = $s->description;
    my $rating_id      = $s->rating_id;
    my $db_title_id    = $s->db_title_id;
    my $based_on_title = $s->based_on_title;
    
    my $selected_original;
    my $selected_existing;
    
    if ($db_title_id) {
        $selected_existing = "checked";
        $AnimeSelectBox = WorldOfAnime::Controller::DAO_ArtStory::PopulateAnimeBoxSelected( $c, $db_title_id );
    } else {
        $selected_original = "checked";
    }
    
    my $RatingSelectHTML = WorldOfAnime::Controller::DAO_ArtStory::GetRatingSelectHTML( $c, $rating_id );
    
    my $chapter = $c->req->params->{'chapter'};

$EditHTML .= <<EndOfHTML;    
<form class="removable_button" action="/artist/fiction/edit_title" method="post" id="begin_fiction_form">
<input type="hidden" name="story_id" value="$story_id">
<input type="hidden" name="chapter" value="$chapter">

    Edit Your Fan Fiction!

    <p>

    <fieldset>
    <label for="fiction-title">Title</label>    
    <input type="text" name="fiction_title" value="$story_title" size="45" maxlength="255" id="fiction-title">
    <p>
    <label for="fiction-rating">Rating</label>    
    $RatingSelectHTML
    <p>
    <label for="fiction-type">Is this an original story, or is it based off of an existing anime?</label>
    <input type="radio" name="existing" value="0" onclick="javascript:hideAnime();" $selected_original>Original story<br>
    <input type="radio" name="existing" value="1" onclick="javascript:populateAnime();" $selected_existing>Based of an existing anime
    <p>
    <div id="anime_selection">$AnimeSelectBox</div>
    </fieldset>
    
    <p>

    <fieldset>
    <label for="fiction-description">Short Description of your Fan Fiction</label>
    <textarea name="description" rows="3" cols="64" id="fiction-description">$description</textarea>
    </fieldset>

    <input type="submit" value="Edit Fan Fiction Title" class="final_removable">

</form>
EndOfHTML

    $c->response->body($EditHTML);
    
}



sub setup_edit_chapter :Path('/artist/fiction/ajax/setup_edit_chapter') :Args(1) {
    my ( $self, $c, $chapter_id ) = @_;
    my $EditHTML;
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $user_id  = $u->{'id'};

    # Get the actual chapter
    my $chap = $c->model('Art::StoryChapter');
    $chap->build( $c, $chapter_id );
    
    my $title   = $chap->chapter_title;
    my $content = $chap->chapter_content;

$EditHTML .= <<EndOfHTML;    
<form class="removable_button" action="/artist/fiction/edit_chapter" method="post" id="begin_fiction_form">
<input type="hidden" name="chapter_id" value="$chapter_id">

    Edit Your Chapter

    <fieldset>
    <label for="chapter-title">Chapter Title</label>
    <input type="text" name="title" id="chapterTitle" size="45" maxlength="255" id="chapter-title" value="$title">
    <p>
    <textarea id="chapterContent" name="content" cols="45" rows="45">$content</textarea>
    <p>
    
    <input type="submit" value="Edit Chapter" class="final_removable">

</form>
EndOfHTML

    $c->response->body($EditHTML);
    
}


__PACKAGE__->meta->make_immutable;

1;
