package WorldOfAnime::Controller::DAO_ArtStory;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


sub GetRatingSelectHTML :Local {
    my ( $c, $rating_id ) = @_;
    my $RatingSelectHTML;
    
    $RatingSelectHTML .= "<select name=\"rating\" id=\"fiction-rating\">\n";
    $RatingSelectHTML .= "<option value=\"\"><- Select Rating -></option>\n";
    
    my $Ratings = $c->model('DB::ArtStoryRatings')->search(
        {
        },
        { order_by => 'display_order ASC' });
    
    if ($Ratings) {
        while (my $r = $Ratings->next) {
            $RatingSelectHTML .= "<option value=\"" . $r->id . "\"";
            if ($r->id == $rating_id) {
                $RatingSelectHTML .= " selected";
            }
            $RatingSelectHTML .= ">" . $r->rating . "</option>\n";
        }
    }
    
    $RatingSelectHTML .= "</select>\n";
    
    return $RatingSelectHTML;    
}



sub PopulateAnimeBox :Path('/artists/fiction/ajax/populate_anime_box') {
    my ( $self, $c ) = @_;
    my $AnimeSelectHTML;
    
    $AnimeSelectHTML .= "Which anime is your fan fiction based on?<br>\n";
    $AnimeSelectHTML .= "<select name=\"anime_title_id\" id=\"anime-title-id\">\n";
    $AnimeSelectHTML .= "<option value=\"\"><-- Select Anime Title --></option>\n";
    
    my $AnimeTitles = $c->model("DB::DBTitles")->search( {
        active => 1,
    },
    {
	order_by => 'english_title ASC',
    });
    
    if ($AnimeTitles) {
        while (my $t = $AnimeTitles->next) {
            $AnimeSelectHTML .= "<option value=\"" . $t->static_id . "\">" . $t->english_title . "</option>\n";
        }
    }
    
    $AnimeSelectHTML .= "</select>\n";
    $AnimeSelectHTML .= "<p>If you do not see the anime your fan fiction is based on, please add it to the <a href=\"/anime/add_title\">Anime Database</a> first.\n";
    
    $c->response->body($AnimeSelectHTML);
}


sub PopulateAnimeBoxSelected :Local {
    my ( $c, $selected_id ) = @_;
    my $AnimeSelectHTML;
    
    $AnimeSelectHTML .= "Which anime is your fan fiction based on?<br>\n";
    $AnimeSelectHTML .= "<select name=\"anime_title_id\" id=\"anime-title-id\">\n";
    $AnimeSelectHTML .= "<option value=\"\"><-- Select Anime Title --></option>\n";
    
    my $AnimeTitles = $c->model("DB::DBTitles")->search( {
        active => 1,
    },
    {
	order_by => 'english_title ASC',
    });
    
    if ($AnimeTitles) {
        while (my $t = $AnimeTitles->next) {
            my $select = "";
            if ($t->static_id == $selected_id) { $select = "selected"; }
            $AnimeSelectHTML .= "<option value=\"" . $t->static_id . "\" $select>" . $t->english_title . "</option>\n";
        }
    }
    
    $AnimeSelectHTML .= "</select>\n";
    $AnimeSelectHTML .= "<p>If you do not see the anime your fan fiction is based on, please add it to the <a href=\"/anime/add_title\">Anime Database</a> first.\n";
    
    return $AnimeSelectHTML;
}


sub GetStoryCount :Private {
    my ( $c ) = @_;    
    my %StoryCount;
    my %StoryID;
    
    my $Fiction = $c->model('DB::ArtStoryTitle')->search({
        -and => [
            db_title_id => { '!=', 0 },
            publish => 1,
            'db_title_rel.active' => 1,
        ],
        },{
        'select' => [ 'me.db_title_id', 'count(db_title_rel.english_title) as num_of_stories', 'db_title_rel.english_title' ],
        'as' => [ 'db_title_id', 'num_of_stories', 'english_title' ],
        'join'     => 'db_title_rel',
        'group_by' => [qw/ db_title_rel.english_title /]
    });

    if (defined($Fiction)) {
        while (my $story = $Fiction->next) {
            my $id    = $story->db_title_id;
            my $title = $story->db_title_rel->english_title;
            my $count = $story->get_column('num_of_stories');
            
            $StoryID{$title}    = $id;
            $StoryCount{$title} = $count;
        }
    }
    
    return (\%StoryCount, \%StoryID);
}


sub GetFictionByTitleID :Private {
    my ( $c, $id ) = @_;
    
    my $Fiction = $c->model('DB::ArtStoryTitle')->search({
        -and => [
            db_title_id => $id,
            publish => 1,
        ],
    });
    
    if (defined($Fiction)) {
        #while (my $story = $Fiction->next) {
        #    my $id    = $story->db_title_id;
        #    my $title = $story->db_title_rel->english_title;
        #    
        #    $StoryID{$title}    = $id;
        #    $StoryCount{$title} = $count;
        #}
        
        return $Fiction;
    }    
    
}


sub GetChapterID :Private {
    my ( $c, $story_id, $chapter_num ) = @_;
    my $chapter_id;

    my $cid = "worldofanime:chapter_id:$story_id:$chapter_num";
    $chapter_id = $c->cache->get($cid);
    
    unless ($chapter_id) {
        my $Chapter = $c->model('DB::ArtStoryChapter')->find({
                story_id => $story_id,
                chapter_num => $chapter_num,
        });
        
        if (defined($Chapter)) {
            $chapter_id = $Chapter->id;

            # Set memcached object for 30 days
            $c->cache->set($cid, $chapter_id, 2592000);        
        }

    }
    
    return $chapter_id;
}


sub GetChapterNum :Private {
    my ( $c, $chapter_id ) = @_;
    my $chapter_num;

    my $cid = "worldofanime:chapter_num:$chapter_id";
    $chapter_num = $c->cache->get($cid);
    
    unless ($chapter_num) {
        my $Chapter = $c->model('DB::ArtStoryChapter')->find({
                id => $chapter_id,
        });
        
        if (defined($Chapter)) {
            $chapter_num = $Chapter->chapter_num;

            # Set memcached object for 30 days
            $c->cache->set($cid, $chapter_num, 2592000);        
        }

    }
    
    return $chapter_num;
}



sub GetArtStoryCommentCacheable :Local :Args(1) {
    my ( $c, $id ) = @_;
    
    my %comment;
    my $comment_ref;
    
    my $cid = "worldofanime:art_story_article_comment:$id";
    $comment_ref = $c->cache->get($cid);
    
    unless ($comment_ref) {
	my $Comment  = $c->model('DB::ArtStoryComments')->find({ id => $id });
	
	if (defined($Comment)) {

	    $comment{'id'}           = $Comment->id;
            $comment{'user_id'}      = $Comment->user_id;
	    $comment{'username'}     = $Comment->story_commentor->username;
            $comment{'filename'}     = $Comment->story_commentor->user_profiles->user_profile_image_id->filename;
	    $comment{'createdate'}   = $Comment->createdate;
            $comment{'comment'}      = $c->model('Formatter')->clean_html($Comment->comment);
            
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%comment, 2592000);
	
	
    } else {
	%comment = %$comment_ref;
    }

    return \%comment;    
}


sub GetArtStoryComments {
    my ( $c, $story_id, $chapter_id, $latest, $get_latest_id ) = @_;
    my $Comments;
    
    $Comments = $c->model('DB::ArtStoryComments')->search({
        chapter_id => $chapter_id,
        id => { '>' => $latest },
    }, {
        order_by => 'createdate DESC'
       });
    
    if ($get_latest_id) {
        # We need to calculate the latest comment id
        
        my $latest_id = 0;

        my $Latest = $c->model('DB::ArtStoryComments')->search({
        chapter_id => $chapter_id,
        id => { '>' => $latest },
    }, {
        rows => 1,
        order_by => 'createdate DESC'
       });

        if ($Latest->count) {
            my $l = $Latest->next;
            $latest_id = $l->id;
        }
        return ($Comments, $latest_id);
    } else {
        return $Comments;
    }
}


sub GetLatestChapter {
    my ( $c ) = @_;
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";    
    my $HTML;
    
    my $Chapter = $c->model('DB::ArtStoryChapter')->search({
            publish => 1,
        }, {
        rows => 5,
        order_by => 'createdate DESC'
    });
    
    if (defined($Chapter)) {
        while (my $ch = $Chapter->next) {
            my $chapter_id = $ch->id;
        
            my $chap = $c->model('Art::StoryChapter');
            $chap->build( $c, $chapter_id );        
        
            my $displayPostDate = WorldOfAnime::Controller::Root::PrepareDate($chap->createdate, 1, $tz);
            my $writer_id       = $chap->user_id;
            my $chapter_num     = $chap->chapter_num;
            my $story_id        = $chap->story_id;
        
            my $p = $c->model('Users::UserProfile');
            $p->build( $c, $writer_id );
            my $writer_name = $p->username;
        
            my $s = $c->model('Art::Story');
            $s->build( $c, $story_id);

            my $title = $s->title;
            my $pretty_title = $s->pretty_title;

            $HTML .= "<a href=\"/profile/$writer_name\">$writer_name</a> has written <a href=\"/artist/fiction/view_story/$story_id/$chapter_num/$pretty_title\">Chapter $chapter_num</a> of <a href=\"/artist/fiction/view_story/$story_id/1/$pretty_title\">$title</a> on $displayPostDate<p>\n";            
        
        }
    }
    
    return $HTML;
}


sub IsSubscribed :Local {
    my ( $c, $story_id, $user_id ) = @_;
    my $IsSub = 0; # Assume no
    
    my $cid = "worldofanime:story_sub:$story_id:$user_id";
    $IsSub = $c->cache->get($cid);
    
    # If they are explicitly subscribed or not subscribed in memcached, return it
    if (defined($IsSub)) { return $IsSub; }
    
    # Otherwise, we need to check their subscription status, cache it, then return it
    
    my $Subscription = $c->model('DB::ArtStorySubscriptions')->search({
        -and => [
            subscriber_user_id => $user_id,
            subscribed_to_story_id => $story_id,
        ],
    });
    
    if ($Subscription->count) {
        $IsSub = 1;
    } else {
        $IsSub = 0;
    }
    
    # Set memcached object for 30 days
    $c->cache->set($cid, $IsSub, 2592000);
    
    return $IsSub;
}


sub GetSubscribers_JSON :Local {
    my ( $c, $id ) = @_;
    my $subscribers;
    
    my $cid = "worldofanime:subscribers:$id";
    $subscribers = $c->cache->get($cid);

    unless ($subscribers) {
        my $Subscriptions = $c->model('DB::ArtStorySubscriptions')->search({
            subscribed_to_story_id => $id,
    }); 

            while (my $sub = $Subscriptions->next) {
		my $sub_id = $sub->subscriber_user_id;

		push (@{ $subscribers}, { 'user_id' => "$sub_id" });
	    }

	
	# Set memcached object for 30 days
	$c->cache->set($cid, $subscribers, 2592000);

    }
    
    if ($subscribers) { return to_json($subscribers); }
}


sub Subscribe :Local {
    my ( $c, $story_id, $user_id ) = @_;

    my $cid = "worldofanime:story_sub:$story_id:$user_id";

    $c->model('DB::ArtStorySubscriptions')->create({
        subscriber_user_id => $user_id,
        subscribed_to_story_id => $story_id,
        create_date => undef,
    });
    
    # Set memcached object for 30 days
    $c->cache->set($cid, 1, 2592000);    
}


sub Unsubscribe :Local {
    my ( $c, $story_id, $user_id ) = @_;

    my $cid = "worldofanime:story_sub:$story_id:$user_id";

    my $Subscription = $c->model('DB::ArtStorySubscriptions')->search({
        -and => [
            subscriber_user_id => $user_id,
            subscribed_to_story_id => $story_id,
        ],
    });
    
    $Subscription->delete;
    
    # Set memcached object for 30 days
    $c->cache->set($cid, 0, 2592000);
}


sub CleanStoryChapters {
    my ( $c, $story_id ) = @_;
    
}

sub CleanChapter {
    my ( $c, $chapter_id ) = @_;
    
}


sub CleanSubscribers {
    my ( $c, $story_id ) = @_;
    
    $c->cache->remove("worldofanime:subscribers:$story_id");
}

__PACKAGE__->meta->make_immutable;

1;
