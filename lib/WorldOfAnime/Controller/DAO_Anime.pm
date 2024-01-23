package WorldOfAnime::Controller::DAO_Anime;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }



sub GetCategorySelectHTML :Local {
    my ( $c, $category_id ) = @_;
    my $CategorySelectHTML;
    
    $CategorySelectHTML .= "<select name=\"category\">\n";
    $CategorySelectHTML .= "<option value=\"\"><- Select Category -></option>\n";
    
    my $Categories = $c->model('DB::DBCategories')->search(
        {
        },
        { order_by => 'display_order ASC' });
    
    while (my $c = $Categories->next) {
        $CategorySelectHTML .= "<option value=\"" . $c->id . "\"";
        if ($c->id == $category_id) {
            $CategorySelectHTML .= " selected";
        }
        $CategorySelectHTML .= ">" . $c->name . "</option>\n";
    }
    
    $CategorySelectHTML .= "</select>\n";
    
    return $CategorySelectHTML;    
}


sub GetGenresSelectHTML :Local {
    my ( $c, $Title ) = @_;
    my $GenresSelectHTML;
    
    # This is if we pass in a title, we want to pre-populate the already chosen genres
    my %AlreadyChosen;
    
    if ($Title) {
        my $genres = $Title->titles_to_genres;
        
        while (my $g = $genres->next) {
            if ($g->active) {
                $AlreadyChosen{$g->db_genre_id} = 1;
            }
        }
    }
    
    
    
    $GenresSelectHTML .= "<select name=\"genre\" multiple>\n";
    
    my $Genres = $c->model('DB::DBGenres')->search(
        {
        },
        { order_by => 'display_order ASC' });
    
    while (my $g = $Genres->next) {
        $GenresSelectHTML .= "<option value=\"" . $g->id . "\"";
        if ($AlreadyChosen{$g->id}) {
            $GenresSelectHTML .= " selected";
        }
        $GenresSelectHTML .= ">" . $g->name . "</option>\n";
    }
    
    $GenresSelectHTML .= "</select>\n";
    
    return $GenresSelectHTML;    
}


sub EpisodeSelector :Local {
    my ( $c, $title_id, $num_episodes ) = @_;
    my %EpisodesInDB;
    my $SelectorHTML;
    
    my $cid = "worldofanime:episode_selector:$title_id";
    $SelectorHTML = $c->cache->get($cid);
    
    unless ($SelectorHTML) {
        
        my $Episodes = $c->model('DB::DBTitlesEpisodes')->search({
            db_title_id => $title_id,
            active      => 1,
        },{
           order_by => 'episode_number ASC',
          });
        
        if ($Episodes) {
            while (my $e = $Episodes->next) {
                $EpisodesInDB{$e->episode_number} = 1;
            }
            
            $SelectorHTML .= "<select id=\"episode_number\" name=\"episode_number\">\n";
            foreach (my $n = 1; $n <= $num_episodes; $n++) {
                unless ($EpisodesInDB{$n}) {
                    $SelectorHTML .= "<option value=\"$n\">$n</option>\n";
                }
            }
            $SelectorHTML .= "</select>\n";
            
        }
    }

    # Set memcached object for 30 days
    $c->cache->set($cid, $SelectorHTML, 2592000);
            
    return $SelectorHTML;    
}


sub FetchEpisodeID :Local {
    my ( $c, $title_id, $episode_num ) = @_;
    my $episode_id;

    my $cid = "worldofanime:episode_id:$title_id:$episode_num";
    $episode_id = $c->cache->get($cid);
    
    unless ($episode_id) {
    
        my $Episode = $c->model('DB::DBTitlesEpisodes')->search({
            db_title_id    => $title_id,
            episode_number => $episode_num,
            active         => 1,
        });
        
        if ($Episode) {
        
            my $e = $Episode->first;
            $episode_id = $e->id;
            
            # Set memcached object for 30 days
            $c->cache->set($cid, $episode_id, 2592000);
        }
    }
    
    return $episode_id;
}


sub FetchGenreIDByName :Local {
    my ( $c, $genre ) = @_;
    my $genre_id;
    
    my $cid = "worldofanime:genre_id:$genre";
    $genre_id = $c->cache->get($cid);
    
    unless ($genre_id) {
        
        my $Genres = $c->model('DB::DBGenres')->search( { } );
        
        if ($Genres) {
            while (my $g = $Genres->next) {
                my $name = $c->model('Formatter')->prettify( $g->name );
                if ($name eq $genre) {
                    
                    $genre_id = $g->id;
                    
                    # Set memcached object for 30 days
                    $c->cache->set($cid, $genre_id, 2592000);
                    
                    return $genre_id;
                }
            }
        }
    }
}


sub GetNewestEpisode :Local {
    my ( $c ) = @_;
    my %newest_episode;
    my $newest_episode_ref;
    
    my $cid = "worldofanime:newest_anime_episode";
    $newest_episode_ref = $c->cache->get($cid);
    unless ($newest_episode_ref) {
	my $Episode = 
	
	#if (defined($User)) {
	    
	    #$user{'id'}               = $User->id;
	    #$user{'username'}         = $User->username;
	    #$user{'email'}            = $User->email;	    
	    #$user{'profile_image_id'} = $User->user_profiles->profile_image_id;
	    #$user{'filedir'}          = $User->user_profiles->user_profile_image_id->filedir;
	    #$user{'filename'}         = $User->user_profiles->user_profile_image_id->filename;
	    #$user{'image_height'}     = $User->user_profiles->user_profile_image_id->height;
	    #$user{'image_width'}      = $User->user_profiles->user_profile_image_id->width;	    
	    #$user{'joindate'}         = $User->confirmdate;
	#}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%newest_episode, 2592000);
	
	
    } else {
	%newest_episode = %$newest_episode_ref;
    }       
    
    return \%newest_episode;
}


sub GetNewestAnime :Local {
    my ( $c ) = @_;
    my %newest_anime;
    my $newest_anime_ref;
    
    my $cid = "worldofanime:newest_anime";
    $newest_anime_ref = $c->cache->get($cid);
    unless ($newest_anime_ref) {
        
    } else {
        %newest_anime = %$newest_anime_ref;
    }
    
    return \%newest_anime;
}


sub GetRandomAnime :Local {
    my ( $c ) = @_;
    
    my $RandTitle = $c->model('DB::DBTitles')->search(
        { active => 1 },
        { rows => 1,
          order_by => \'RAND()',
          });
    
    my $t = $RandTitle->next;
    my $random_id = $t->static_id;
    
    my $title = $c->model('Database::AnimeTitle');
    $title->build( $c, $random_id );
    
    return $title;    
}



sub Search :Path('/anime/search') :Args(0) {
    my ( $self, $c ) = @_;
    my $results;
    my $count = 0;

    my $searchString = $c->req->params->{'searchString'};

    my $AnimeTitles = $c->model("DB::DBTitles")->search( {
        -and => [
            -or => [
                english_title => { 'like', "%$searchString%" },
                description => { 'like', "%$searchString%" },
            ],
                active => 1,
        ]            
    },
    {
	order_by => 'english_title ASC',
    });

        if ($AnimeTitles) {
            while (my $t = $AnimeTitles->next) {
                my $type;
                
                my $id    = $t->static_id;
                my $title = $t->english_title;
                eval { $type  = $t->category->name };
                my $year  = $t->publish_year;
                my $pretty_title = $c->model('Formatter')->prettify( $title );
	    
                push (@{ $results}, { 'title' => "$title", 'id' => "$id", 'pretty_title' => "$pretty_title", 'type' => "$type", 'year' => "$year" });
                $count++;
            }
        }

    WorldOfAnime::Controller::DAO_Searches::RecordSearch( $c, 1, $searchString, $count );
    
    if ($results) {
        my $json_text = to_json($results);
        $c->stash->{results} = $json_text;
        $c->forward('View::JSON');
    } else {
        $c->response->body('N');
    }
}


sub GetReviewComments {
    my ( $c, $id, $latest, $get_latest_id ) = @_;
    my $Comments;
    
    $Comments = $c->model('DB::DBTitleReviewComments')->search({
        db_title_review_id => $id,
    }, {
        rows => 1,
        order_by => 'createdate DESC'
       });
    
    if ($get_latest_id) {
        # We need to calculate the latest comment id
        
        my $latest_id = 0;

        my $Latest = $c->model('DB::DBTitleReviewComments')->search({
        db_title_review_id => $id,
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


sub GetLatestReview {
    my ( $c ) = @_;
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";    
    my $HTML;
    my $image_id;
    
    my $Reviews = $c->model('DB::DBTitleReviews')->search({
        }, {
        rows => 1,
        order_by => 'createdate DESC'
    });
    
    if (defined($Reviews)) {
        my $r = $Reviews->next;
        my $review_id = $r->id;
        
        my $Review = $c->model('Reviews::AnimeReview');
        $Review->build( $c, $review_id );
        
        my $displayPostDate = WorldOfAnime::Controller::Root::PrepareDate($Review->createdate, 6, $tz);
        my $title_id        = $Review->db_title_id;
        my $reviewer        = $Review->reviewer;
        my $rating          = "Rating: " . $Review->rating . " / 10<p>";
        my $description     = $Review->review;
        if (length($description) > 250) {
            $description = substr($description, 0, 250);
            $description .= "...";
        }
	
	$description = $c->model('Formatter')->clean_html($description);
        
        my $Title = $c->model('Database::AnimeTitle');
        $Title->build( $c, $title_id );
    
        my $pretty_title  = $Title->pretty_title;
        my $english_title = $Title->english_title;

	my $i = $c->model('Images::Image');
	$i->build($c, $Title->profile_image_id);
	my $image_url = $i->thumb_url;	
	
	$image_id         = $Title->profile_image_id;
        
        $HTML .= "<h2><a href=\"/anime/$title_id/$pretty_title/review/$review_id\">$english_title</a></h2>\n";
        $HTML .= "<a href=\"/anime/$title_id/$pretty_title/review/$review_id\"><img src=\"$image_url\"></a>\n";
        $HTML .= $rating;
        $HTML .= $description;
        $HTML .= "<p class=\"byline\">Reviewed by <a href=\"/profile/$reviewer\">$reviewer</a> on $displayPostDate</p>\n";            
        
    }
    
    return ($HTML, $image_id);
}


sub UserAnimeRating :Local {
    my ( $c, $title_id ) = @_;

    return "C" unless ($c->user_exists());  # Can't rate if not logged in
    
    my $user_rating;
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $cid = "woa:db_title_user_rating:$title_id:$user_id";
    $user_rating = $c->cache->get($cid);
    
    unless ($user_rating) {
        $user_rating = "N";  # Assume N for Not Rated Yet
        
        # First, look in ratings table
        
        my $Rating = $c->model('DB::DBRatings')->search({
            -AND => [
                db_title_id => $title_id,
                user_id => $user_id,
            ]});
        
        if (defined($Rating)) {
            my $r = $Rating->next;
            
            if ($r) {
                $user_rating = $r->rating;
            }
        }
        
        
        # Now, look in reviews table
        
        if ($user_rating eq "N") {  # Still not rated
            
            my $Review = $c->model('DB::DBTitleReviews')->search( {
                -AND => [
                    db_title_id => $title_id,
                    user_id => $user_id,
                ]});
	
            if (defined($Review)) {
                my $r = $Review->next;

                if ($r) {
                    $user_rating = $r->rating;
                }
            }
        }
        
        $c->cache->set($cid, $user_rating, 2592000);
    }
    
    return $user_rating;
}



sub CleanTitleCache :Local {
    my ( $c, $title_id ) = @_;
    
    $c->cache->remove("worldofanime:episode_selector:$title_id");
    $c->cache->remove("worldofanime:db_title:$title_id");
    $c->cache->remove("worldofanime:newest_anime_episode");
    $c->cache->remove("worldofanime:newest_anime");
}


sub CleanEpisodeCache :Local {
    my ( $c, $title_id, $episode_num ) = @_;
    
    $c->cache->remove("worldofanime:episode_id:$title_id:$episode_num");
    $c->cache->remove("worldofanime:db_title:$title_id");    
    $c->cache->remove("worldofanime:newest_anime_episode");
    $c->cache->remove("worldofanime:newest_anime");        
}



__PACKAGE__->meta->make_immutable;

1;
