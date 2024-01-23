package WorldOfAnime::Controller::Anime;
use Moose;
use JSON;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $Genres = $c->model('DB::DBGenres')->search({ },
        { order_by => 'name ASC' }
      );
    
    $c->stash->{images_approved} = 1;
    $c->stash->{Genres}   = $Genres;
    $c->stash->{template} = 'anime/main_anime.tt2';
}


sub setup_add_title :Path('/anime/add_title') :Args(0) {
    my ( $self, $c ) = @_;

    my $GenresSelectHTML = WorldOfAnime::Controller::DAO_Anime::GetGenresSelectHTML( $c );
    my $CategorySelectHTML = WorldOfAnime::Controller::DAO_Anime::GetCategorySelectHTML( $c );

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff

    $c->stash->{images_approved} = 1;
    $c->stash->{current_uri} = $current_uri;    
    $c->stash->{genres_select}   = $GenresSelectHTML;
    $c->stash->{category_select} = $CategorySelectHTML;
    $c->stash->{template} = 'anime/add_new_title.tt2';
}


sub add_new_title :Path('/anime/add_new_title') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a new anime title.");
    
    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $UserID = $User->id;
    
    # Check to make sure this title doesn't already exist
    
    my $ExistingTitle = $c->model('DB::DBTitles')->find( { english_title => $c->req->params->{'english_title'}, active => 1 });
    if ($ExistingTitle) {
        $c->stash->{error_message} = "I'm sorry, the title \"" . $c->req->params->{'english_title'} . "\" already exists in our database.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();    
    }
    
    
    # If not, add it
    
    my $profile_image_id = 14;  # This is the default "No image" image
    
    # If they uploaded a profile image, upload it and set it to the profile_image_id
    
    if ($c->req->params->{profile_image}) {
        my $upload   = $c->req->upload('profile_image');
        my $filedir  = $c->config->{uploadfiledir};
        my $justfilename = $upload->filename;
        
        $profile_image_id = WorldOfAnime::Controller::DAO_Images::upload_image( $c, $upload, $justfilename);
    }    
    
    
    my $Title = $c->model('DB::DBTitles')->create({
        started_by_user_id => $UserID,
        active => 1,
        category_id => $c->req->params->{'category'},
        english_title => $c->req->params->{'english_title'},
        japanese_title => $c->req->params->{'japanese_title'},
        description => $c->req->params->{'description'},
        publish_year => $c->req->params->{'publish_year'},
        num_episodes => $c->req->params->{'num_episodes'},
        episode_length => $c->req->params->{'episode_length'},
        profile_image_id => $profile_image_id,
        modifydate => undef,
        createdate => undef,
    });
    
    # Now immediately update it static_id to be the same as the auto id

    my $TitleID = $Title->id;
    
    $Title->update({
        static_id => $TitleID,
    });
    
    my $pretty_title = $c->model('Formatter')->prettify( $c->req->params->{'english_title'} );
    
    # Assign genres
    
    my $p = $c->request->parameters;
    my @Genres = ref $p->{genre} eq 'ARRAY' ? @{$p->{genre}} : ($p->{genre});
    
    if (@Genres) {
        
        foreach my $g (@Genres) {
            my $Genre = $c->model('DB::DBTitlesToGenres')->create({
                active => 1,
                from_title_edit => $TitleID,
                db_title_id => $TitleID,
                db_genre_id => $g,
            });
        }
    }
    
    
    # Give points
    
    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $User->username . "\">" . $User->username . "</a> has entered ";
    $ActionDescription .= "<a href=\"/anime/" . $Title->id . "/$pretty_title\">" . $c->req->params->{'english_title'} . "</a> ";
    $ActionDescription .= "into the anime <a href=\"/anime\">database</a>.";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $User, $ActionDescription, 22, $TitleID);
    
    
    # Send me an e-mail

    my $username = $User->username;
    my $subject = "Anime Database - New Title Entered.";
    my $EnglishTitle = $c->req->params->{'english_title'};
    my $Description  = $c->req->params->{'description'};
    my $FullLink = 
    
	my $body = <<EndOfBody;
$username has entered the following title into the Anime Database:
Title: $EnglishTitle
Description: $Description

See the full title here:
http://www.worldofanime.com/anime/$TitleID/$pretty_title
EndOfBody
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, $subject);
    
    
    # Redirect immediately to it
    
   $c->response->redirect("/anime/$TitleID/$pretty_title");
   $c->detach();
}


sub main_anime :Path('/anime') :Args(2) {
    my ( $self, $c, $title_id, $pretty_title ) = @_;
    my @image_ids;
    
    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    push (@image_ids, $Title->profile_image_id);
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff   

    $Title->get_ratings( $c );
    my $UserRating = WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id );
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{Title}       = $Title;
    $c->stash->{UserRating}  = $UserRating;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template}    = 'anime/main_title.tt2';
}


sub browse :Path('/anime/browse') :Args(0) {
    my ( $self, $c ) = @_;
    my $page = $c->req->params->{'page'} || 1;
    my $sort_order = $c->req->params->{'sort'} || "title";
    
    my $Anime = $c->model('DB::DBTitles')->search({ active => 1 }
    ,{
      page      => "$page",
      rows      => 35,   
      order_by  => 'english_title ASC',
      prefetch => { 'category' }
      });

    my $pager = $Anime->pager();

    $c->stash->{pager}    = $pager;        

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    $c->stash->{images_approved} = 1;
    $c->stash->{Anime}    = $Anime;
    $c->stash->{current_uri} = $current_uri;    
    $c->stash->{template} = 'anime/browse.tt2';
}


sub browse_genre :Path('/anime/browse/genre') :Args(1) {
    my ( $self, $c, $genre ) = @_;
    my $page = $c->req->params->{'page'} || 1;
    my $sort_order = $c->req->params->{'sort'} || "title";    
    
    my $genre_id   = WorldOfAnime::Controller::DAO_Anime::FetchGenreIDByName( $c, $genre );
    my $Genre = $c->model('DB::DBGenres')->find({ id => $genre_id });
    
    my $Titles = $c->model('DB::DBTitlesToGenres')->search( { db_genre_id => $genre_id, 'me.active' => 1, 'title_id.active' => 1 },
        {
            page      => "$page",
            rows      => 35,
            order_by  => 'english_title ASC',            
            prefetch => { title_id => 'category' }
        });
    
    my $pager = $Titles->pager();

    $c->stash->{pager}    = $pager;        

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    $c->stash->{images_approved} = 1;
    $c->stash->{Titles}   = $Titles;
    $c->stash->{Genre}    = $Genre;
    $c->stash->{template} = 'anime/browse.tt2';
}



##### Branching #####
sub branch3 :Path('/anime') :Args(3) {
    my ( $self, $c, $title_id, $pretty_title, $action ) = @_;
    
    if ($action eq "episodes") {
        $c->forward('episode_list');
    }

    if ($action eq "reviews") {
        $c->forward('reviews');
    }
    
    if ($action eq "fan_fiction") {
        $c->forward('fan_fiction');
    }
    
    if ($action eq "ratings") {
        $c->forward('all_ratings');
    }        
    
    if ($action eq "add_new_episode") {
        $c->forward('add_new_episode');
    }
    
    if ($action eq "submit_review") {
        $c->forward('add_new_review');
    }
    
    if ($action eq "store") {
        $c->forward('title_store');
    }    
    
}


##### Branching #####
sub branch4 :Path('/anime') :Args(4) {
    my ( $self, $c, $title_id, $pretty_title, $action1, $action2 ) = @_;
    
    if ($action1 eq "review") {
        $c->forward('specific_review');
    }
    
}


sub branch5 :Path('/anime') :Args(5) {
    my ( $self, $c, $title_id, $pretty_title, $action, $episode_num, $pretty_episode_title ) = @_;
    
    if ($action eq "episodes") {
        $c->forward('specific_episode');
    }
}

##### End Branching #####


sub title_store :Local {
    my ( $self, $c, $title_id, $pretty_title, $action) = @_;
    
    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    
    # Get Items at Store
    
    $c->stash->{Title} = $Title;
    $c->stash->{template} = 'anime/title_store.tt2';
}


sub episode_list :Local {
    my ( $self, $c, $title_id, $pretty_title, $action ) = @_;
    my @image_ids;
    
    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    $Title->get_ratings( $c );
    push (@image_ids, $Title->profile_image_id);
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    my $Episodes = $c->model('DB::DBTitlesEpisodes')->search({
        db_title_id => $title_id,
        active      => 1,
    },{
       order_by => 'episode_number ASC',
      });
    
    my $EpisodeSelector = WorldOfAnime::Controller::DAO_Anime::EpisodeSelector( $c, $title_id, $Title->num_episodes );

    my $UserRating = WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id );
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );    
    $c->stash->{Title}    = $Title;
    $c->stash->{UserRating}  = $UserRating;
    $c->stash->{Episodes} = $Episodes;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{pretty_title} = $pretty_title;
    $c->stash->{EpisodeSelector} = $EpisodeSelector;
    $c->stash->{template} = 'anime/episode_list.tt2';    
}


sub fan_fiction :Local {
    my ( $self, $c, $title_id, $pretty_title, $action ) = @_;
    my @image_ids;

    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    $Title->get_ratings( $c );
    push (@image_ids, $Title->profile_image_id);   
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    my $Fiction = WorldOfAnime::Controller::DAO_ArtStory::GetFictionByTitleID( $c, $title_id );

    my $UserRating = WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id );
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );    
    $c->stash->{Title}    = $Title;
    $c->stash->{UserRating}  = $UserRating;
    $c->stash->{Fiction}  = $Fiction;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'anime/fan_fiction.tt2';        
}


sub all_ratings :Local {
    my ( $self, $c, $title_id, $pretty_title, $action ) = @_;
    my @image_ids;

    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    $Title->get_ratings( $c );
    $Title->get_all_ratings( $c );
    push (@image_ids, $Title->profile_image_id);    
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    my $Ratings = WorldOfAnime::Controller::DAO_ArtStory::GetFictionByTitleID( $c, $title_id );

    my $UserRating = WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id );
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );    
    $c->stash->{Title}    = $Title;
    $c->stash->{UserRating}  = $UserRating;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'anime/all_ratings.tt2';        
}


sub reviews :Local {
    my ( $self, $c, $title_id, $pretty_title, $action ) = @_;
    my @image_ids;

    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    $Title->get_ratings( $c );
    push (@image_ids, $Title->profile_image_id);    
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    $Title->get_reviews( $c );
    
    # Make sure this person has not already written a review for this anime

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    if ($user_id) {
    
	my $Review = $c->model('Reviews::AnimeReview');
        $Review->from_user_title( $c, $user_id, $title_id );

	if ( ($Review->id) > 1 ) {
	    # A review for this title and user_id already exists
        
	    $c->stash->{existing_review} = $Review;

	} else {
        
	    $c->stash->{can_review} = 1;
	}
	
    }
    
    # Just in case they've already rated...
    
    my $UserRating = WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id );
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );    
    $c->stash->{Title}    = $Title;
    $c->stash->{Reviews}  = $Title->reviews;
    $c->stash->{UserRating}  = $UserRating;    
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'anime/main_reviews.tt2';        
}


sub specific_review :Local {
    my ( $self, $c, $title_id, $pretty_title, $action, $review_id ) = @_;
    my @image_ids;
    my $CommentsHTML;
    my $count = 0;

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $get_latest_id = 1;
    
    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    $Title->get_ratings( $c );
    push (@image_ids, $Title->profile_image_id);   
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    my $Review = $c->model('Reviews::AnimeReview');
    $Review->build( $c, $review_id );
    $Review->get_comments( $c );
    
    my $reviews;
	
    if ($Review->comments) { $reviews = from_json( $Review->comments ); }

    my @profile_ids;
    foreach my $review (@{ $reviews}) {    
	push (@profile_ids, $review->{user_id});
    }

    my @profile_image_ids = WorldOfAnime::Controller::DAO_Users::GetProfileImageIDs( $c, @profile_ids );
    push (@image_ids, @profile_image_ids);
    
    my $UserRating = WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id );
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );        
    $c->stash->{Title}    = $Title;
    $c->stash->{UserRating}  = $UserRating;    
    $c->stash->{Review}   = $Review;
    $c->stash->{template} = 'anime/specific_review.tt2';            
}


sub specific_episode :Local {
    my ( $self, $c, $title_id, $pretty_title, $action1, $episode_num, $pretty_episode_title ) = @_;
    my @image_ids;

    my $episode_id = WorldOfAnime::Controller::DAO_Anime::FetchEpisodeID($c, $title_id, $episode_num);
    
    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    $Title->get_ratings( $c );
    push (@image_ids, $Title->profile_image_id);    
    
    my $Episode = $c->model('DB::DBTitlesEpisodes')->find({ id => $episode_id });
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    my $UserRating = WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id );
    
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );    
    $c->stash->{Title}    = $Title;
    $c->stash->{UserRating}  = $UserRating;        
    $c->stash->{Episode}  = $Episode;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{pretty_title} = $pretty_title;
    $c->stash->{template} = 'anime/specific_episode.tt2';
}


sub add_new_episode :Local {
    my ( $self, $c, $title_id, $pretty_title, $action ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a new anime episode.");
    
    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $UserID = $User->id;

    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );    
    
    # Make sure this episode doesn't already exist

    my $ExistingEpisode = $c->model('DB::DBTitlesEpisodes')->find( { db_title_id => $title_id, episode_number => $c->req->params->{'episode_number'}, active => 1 });
    if ($ExistingEpisode) {
        $c->stash->{error_message} = "I'm sorry, that episode already exists in our database.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();    
    }
    
    
    
    # Ok, add it

    my $original_airdate = $c->req->params->{'original_airyear'} . "-" . $c->req->params->{'original_airmonth'} . "-" . $c->req->params->{'original_airday'};
    unless ($original_airdate) { $original_airdate = "0"; }
    
    my $english_airdate = $c->req->params->{'english_airyear'} . "-" . $c->req->params->{'english_airmonth'} . "-" . $c->req->params->{'english_airday'};
    unless ($english_airdate) { $english_airdate = "0"; }
    
    
    my $Episode = $c->model('DB::DBTitlesEpisodes')->create({
        added_by_user_id => $UserID,
        active => 1,
        db_title_id => $title_id,
        episode_number => $c->req->params->{'episode_number'},
        english_title  => $c->req->params->{'english_title'},
        japanese_title => $c->req->params->{'japanese_title'},
        original_airdate => $original_airdate,
        english_airdate => $english_airdate,
        length => $c->req->params->{'length'},
        description => $c->req->params->{'description'},
        modifydate => undef,
        createdate => undef,
    });
    
    my $pretty_episode_title = $c->model('Formatter')->prettify( $c->req->params->{'english_title'} );
    
    # Clean relevant memcached entries
    
    WorldOfAnime::Controller::DAO_Anime::CleanTitleCache($c, $title_id);

    # Give points
    
    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $User->username . "\">" . $User->username . "</a> has entered ";
    $ActionDescription .= "<a href=\"/anime/" . $title_id . "/$pretty_title/episodes/" . $c->req->params->{'episode_number'};
    $ActionDescription .= "/$pretty_episode_title\">episode " . $c->req->params->{'episode_number'} . "</a> of ";
    $ActionDescription .= "<a href=\"/anime/" . $title_id . "/$pretty_title\">" . $Title->english_title . "</a> ";
    $ActionDescription .= "into the anime <a href=\"/anime\">database</a>.";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $User, $ActionDescription, 23, $Episode->id);


    # Send me an e-mail

    my $username = $User->username;
    my $subject       = "Anime Database - New Episode Entered.";
    my $ShowName      =  $Title->english_title;
    my $EnglishTitle  = $c->req->params->{'english_title'};
    my $Description   = $c->req->params->{'description'};
    my $EpisodeNumber = $c->req->params->{'episode_number'};
    
	my $body = <<EndOfBody;
$username has entered the following episode into the Anime Database:
Show Title: $ShowName
Episode Title: $EnglishTitle
Episode Number: $EpisodeNumber
Description: $Description

See the full episode here:
http://www.worldofanime.com/anime/$title_id/$pretty_title/episodes/$EpisodeNumber/$pretty_episode_title
EndOfBody
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, $subject);
    

   $c->response->redirect("/anime/$title_id/$pretty_title/episodes");
   $c->detach();    
}


sub add_new_review :Local {
    my ( $self, $c, $title_id, $pretty_title, $action ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a new review.");
    
    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $UserID = $User->id;

    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    
    # Make sure this person has not already written a review for this anime
    
    my $Review = $c->model('Reviews::AnimeReview');
    $Review->from_user_title( $c, $UserID, $title_id );

    $Review->rating($c->req->params->{'rating'});
    $Review->review($c->req->params->{'review'});
    
    if ($Review->id ) {
        # A review for this title and user_id already exists

    } else {
        # Add Review

        unless ($Review->rating) {
            # This person must have already rated
            # Remove their entry from the ratings table, since we'll be putting it in Reviews
        
            $Review->rating( WorldOfAnime::Controller::DAO_Anime::UserAnimeRating( $c, $title_id ) );
        
            my $Rating = $c->model('DB::DBRatings')->search({
                -AND => [
                    db_title_id => $title_id,
                    user_id => $UserID,
                ]});
        
            $Rating->delete;
        }
            
        
        $Review->add( $c );
        
        $Title->clear_reviews( $c );

        $c->cache->remove("woa:db_title_user_rating:$title_id:$UserID");           
    }
    
    
    
   $c->response->redirect("/anime/$title_id/$pretty_title/reviews");
   $c->detach();        
}



# Ajax Stuff

sub add_new_rating :Path('/anime/ajax/rate') {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to rate an anime.");

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $title_id = $c->req->params->{'title_id'};
    my $rating   = $c->req->params->{'rating'};
    
    # Add the ratings
    
    $c->model('DB::DBRatings')->create({
        db_title_id => $title_id,
        user_id => $user_id,
        rating => $rating,        
    });

    # Remove cache entry for all this titles ratings, and this user's rating of this title
    $c->cache->remove("woa:db_title_ratings:$title_id");
    $c->cache->remove("woa:db_title_all_ratings:$title_id");
    $c->cache->remove("woa:db_title_user_rating:$title_id:$user_id");

    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    $Title->get_ratings( $c );
    
    my $english_title = $Title->english_title;
    my $pretty_title = $Title->pretty_title;
    
    my $p = $c->model('Users::UserProfile');
    $p->build( $c, $user_id );
    my $username = $p->username;
    
    # Give points
    my $ActionDescription = "<a href=\"/profile/$username\">$username</a> gave <a href=\"/anime/" . $title_id . "/$pretty_title\">" . $english_title . "</a>" . " a rating of $rating";
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 34, $title_id);
    
    $c->response->body( $Title->ratings_json );
}


sub load_episode_editable :Path('/anime/ajax/load_episode_editable') :Args(1) {
    my ( $self, $c, $episode_id ) = @_;
    my $EditHTML;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit an episode.");
    
    my $Episode = $c->model('DB::DBTitlesEpisodes')->find({ id => $episode_id });
    
    my $EpisodeNum    = $Episode->episode_number;
    my $EnglishTitle  = $Episode->english_title;
    my $JapaneseTitle = $Episode->japanese_title;
    my $OriginalAirDate = eval { $Episode->original_airdate };
    my $EnglishAirDate  = eval { $Episode->english_airdate };
    my $EpisodeLength   = $Episode->length;
    my $Description     = $Episode->description;
    
    my $OriginalAirYear;
    my $OriginalAirMonth;
    my $OriginalAirDay;
    
    if ($OriginalAirDate) {
        ($OriginalAirYear, $OriginalAirMonth, $OriginalAirDay) = split(/\-/, $OriginalAirDate);
        $OriginalAirDay =~ s/(T.*$)//; # To get rid of the time on the Date field
    }    
    
    my $EnglishAirYear;
    my $EnglishAirMonth;
    my $EnglishAirDay;    
    
    if ($EnglishAirDate) {
        ($EnglishAirYear, $EnglishAirMonth, $EnglishAirDay) = split(/\-/, $EnglishAirDate);
        $EnglishAirDay =~ s/(T.*$)//; # To get rid of the time on the Date field
    }
    
    
    $EditHTML .= <<EndOfHTML;
<div id="new_thread_box" style="display: block;">  
<form action="/anime/edit/episode/$episode_id" method="post">
    <h3>Episode #$EpisodeNum:</h3>
    
    <h3>English Title:</h3>
    <br />
    <span class="form-field"><input type="text" name="english_title" value='$EnglishTitle' size="45" maxlength="255"></span>
    
    <p />
    
    <h3>Japanese Title: (if known)</h3>
    <br />
    <span class="form-field"><input type="text" name="japanese_title" value='$JapaneseTitle' size="45" maxlength="255"></span>
    
    <p />
    
    <h3>Original Air Date: (in Japan)</h3>
    <br />
    <span class="form-field"><input type="text" name="original_airyear" value='$OriginalAirYear' size="4" maxlength="4"> /
    <input type="text" name="original_airmonth" value='$OriginalAirMonth' size="2" maxlength="2"></span> /
    <input type="text" name="original_airday" value='$OriginalAirDay' size="2" maxlength="2"> <span class="normal_text">(YYYY / MM / DD)</span>
    
    <p />

    <h3>Original English Air Date:</h3>
    <br />
    <span class="form-field"><input type="text" name="english_airyear" value='$EnglishAirYear' size="4" maxlength="4"> /
    <input type="text" name="english_airmonth" value='$EnglishAirMonth' size="2" maxlength="2"></span> /
    <input type="text" name="english_airday" value='$EnglishAirDay' size="2" maxlength="2"> <span class="normal_text">(YYYY / MM / DD)</span>
    
    <p />
    
    <h3>Episode Length:</h3>
    <br />
    <span class="form-field"><input type="text" name="length" value='$EpisodeLength' size="4" maxlength="10"></span> <span class="normal_text">minutes</span>
    
    <p />

    <h3>Description</h3>
    <br />
    <span class="form-field"><textarea name="description" rows="8" cols="64">$Description</textarea></span>
    <p />
<input type="Submit" value="Edit This Episode">
</form>
</div>
EndOfHTML
    
    $c->response->body($EditHTML);
}


sub edit_episode :Path('/anime/edit/episode') :Args(1) {
    my ( $self, $c, $episode_id ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit an episode.");

    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $UserID = $User->id;
    
    my $TitleID;
    my $pretty_title;
    my $pretty_episode_title;
    my $EpisodeNumber;
    my $EnglishTitle;
    
    # Current, pre-edit episode
    
    my $Episode = $c->model('DB::DBTitlesEpisodes')->find({ id => $episode_id });

    # Deactivate old entry
    
    if ($Episode) {
        $Episode->update({
            active => 0
        });
        
        $TitleID       = $Episode->db_title_id;
        $EpisodeNumber = $Episode->episode_number;
        $pretty_title  = $c->model('Formatter')->prettify($Episode->title->english_title);
        $EnglishTitle  = $Episode->title->english_title;
    }
    
    # Create new entry
    
    my $original_airdate = $c->req->params->{'original_airyear'} . "-" . $c->req->params->{'original_airmonth'} . "-" . $c->req->params->{'original_airday'};
    unless ($original_airdate) { $original_airdate = "0"; }
    
    my $english_airdate = $c->req->params->{'english_airyear'} . "-" . $c->req->params->{'english_airmonth'} . "-" . $c->req->params->{'english_airday'};
    unless ($english_airdate) { $english_airdate = "0"; }
    
    my $NewEpisode = $c->model('DB::DBTitlesEpisodes')->create({
        added_by_user_id => $UserID,
        active => 1,
        db_title_id => $TitleID,
        episode_number => $EpisodeNumber,
        english_title  => $c->req->params->{'english_title'},
        japanese_title => $c->req->params->{'japanese_title'},
        original_airdate => $original_airdate,
        english_airdate => $english_airdate,
        length => $c->req->params->{'length'},
        description => $c->req->params->{'description'},
        modifydate => undef,
        createdate => undef,
    });

    $pretty_episode_title = $c->model('Formatter')->prettify( $c->req->params->{'english_title'} );
    
    # Clean relevant memcached entries
    
    WorldOfAnime::Controller::DAO_Anime::CleanEpisodeCache($c, $TitleID, $EpisodeNumber);
       
    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $User->username . "\">" . $User->username . "</a> has edited ";
    $ActionDescription .= "<a href=\"/anime/" . $TitleID . "/$pretty_title/episodes/" . $EpisodeNumber;
    $ActionDescription .= "/$pretty_episode_title\">episode " . $EpisodeNumber . "</a> of ";
    $ActionDescription .= "<a href=\"/anime/" . $TitleID . "/$pretty_title\">" . $EnglishTitle . "</a> ";
    $ActionDescription .= "in the anime <a href=\"/anime\">database</a>.";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $User, $ActionDescription, 25, $EpisodeNumber);
    
    
    # Send me an e-mail

    my $username = $User->username;
    my $subject       = "Anime Database - New Episode Edited.";
    my $EpisodeTitle  = $c->req->params->{'english_title'};
    my $Description   = $c->req->params->{'description'};
    
	my $body = <<EndOfBody;
$username has edited the following episode in the Anime Database:
Show Title: $EnglishTitle
Episode Title: $EpisodeTitle
Episode Number: $EpisodeNumber
Description: $Description

See the full episode here:
http://www.worldofanime.com/anime/$TitleID/$pretty_title/episodes/$EpisodeNumber/$pretty_episode_title
EndOfBody

    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, $subject);

    
   $c->response->redirect("/anime/$TitleID/$pretty_title/episodes/$EpisodeNumber/$pretty_episode_title");
   $c->detach();    
}


sub load_title_editable :Path('/anime/ajax/load_title_editable') :Args(1) {
    my ( $self, $c, $title_id ) = @_;
    my $EditHTML;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit a title.");
    
    my $Title = $c->model('DB::DBTitles')->find({ static_id => $title_id, active => 1 });
    
    my $EnglishTitle  = $Title->english_title;
    my $JapaneseTitle = $Title->japanese_title;
    my $PublishYear   = $Title->publish_year;
    my $NumEpisodes   = $Title->num_episodes;
    my $EpisodeLength = $Title->episode_length;
    my $Description   = $Title->description;
    my $CategoryID    = $Title->category_id;
    
    my $CategorySelectHTML = WorldOfAnime::Controller::DAO_Anime::GetCategorySelectHTML( $c, $CategoryID );
    my $GenresSelectHTML = WorldOfAnime::Controller::DAO_Anime::GetGenresSelectHTML( $c, $Title );
    
    
    $EditHTML .= <<EndOfHTML;
<div id="new_thread_box" style="display: block;">    
<form action="/anime/edit/title/$title_id" method="post" enctype="multipart/form-data">
    <h2>Editing $EnglishTitle</h2>
    
    <span class="normal_text">
    (Only upload an image if you want to change the current profile image, otherwise leave this blank)</span>
    <br />
    <h3>Main Profile Image:</h3>
    <br />
    <span class="form-field"><input type="file" name="profile_image" size="30"></span>
    
    <p />    
    
    <h3>English Title:</h3>
    <br />
    <span class="form-field"><input type="text" name="english_title" value='$EnglishTitle' size="45" maxlength="255"></span>
    
    <p />
    
    <h3>Japanese Title: (if known)</h3>
    <br />
    <span class="form-field"><input type="text" name="japanese_title" value='$JapaneseTitle' size="45" maxlength="255"></span>
    
    <p />
    
    <h3>Category:</h3>
    <br />
    <span class="form-field">$CategorySelectHTML</span>

    <p />
    
    <h3>Genres:</h3>
    <br />
    <span class="form-field">$GenresSelectHTML</span>
    
    <p />
    
    <h3>Year Published:</h3>
    <br />
    <span class="form-field"><input type="text" name="publish_year" value="$PublishYear" size="6" maxlength="10"></span>
    
    <p />

    <h3># of Episodes:</h3>
    <br />
    <span class="form-field"><input type="text" name="num_episodes" value="$NumEpisodes" size="4" maxlength="10"></span>
    
    <p />    
    
    <h3>Episode Length:</h3>
    <br />
    <span class="form-field"><input type="text" name="length" value="$EpisodeLength" size="4" maxlength="10"></span> <span class="normal_text">minutes</span>
    
    <p />

    <h3>Description</h3>
    <br />
    <span class="form-field"><textarea name="description" rows="8" cols="64">$Description</textarea></span>
    <p />
<input type="Submit" value="Edit This Title">
</form>
</div>
EndOfHTML
    
    $c->response->body($EditHTML);
}


sub edit_title :Path('/anime/edit/title') :Args(1) {
    my ( $self, $c, $title_id ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit a title.");

    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $UserID = $User->id;

    
    # Current, pre-edit episode

    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );

    my $pretty_title     = $Title->pretty_title;
    my $profile_image_id = $Title->profile_image_id;    

    # Deactivate old entry
    
    $Title->deactivate( $c );

    # If they uploaded a new profile image, upload it and set it to the new profile_image_id
    
    if ($c->req->params->{profile_image}) {
        my $upload   = $c->req->upload('profile_image');
        my $filedir  = $c->config->{uploadfiledir};
        my $justfilename = $upload->filename;
        
        $profile_image_id = WorldOfAnime::Controller::DAO_Images::upload_image( $c, $upload, $justfilename);
    }
    
    # Create new entry
    
    my $NewTitle = $c->model('DB::DBTitles')->create({
        static_id => $title_id,
        active => 1,
        started_by_user_id => $UserID,
        category_id => $c->req->params->{'category'},
        english_title => $c->req->params->{'english_title'},
        japanese_title => $c->req->params->{'japanese_title'},
        description  => $c->req->params->{'description'},
        publish_year => $c->req->params->{'publish_year'},
        num_episodes => $c->req->params->{'num_episodes'},
        episode_length => $c->req->params->{'length'},
        profile_image_id => $profile_image_id,
        modifydate => undef,
        createdate => undef,
    });
    
    
    # Assign genres
    
    my $p = $c->request->parameters;
    my @Genres = ref $p->{genre} eq 'ARRAY' ? @{$p->{genre}} : ($p->{genre});
    
    if (@Genres) {
        
        # First, deactivate all current genres
        
        my $CurrentGenres = $c->model('DB::DBTitlesToGenres')->search({
            active => 1,
            db_title_id => $title_id,
        });
        
        $CurrentGenres->update({
            active => 0,
        });
        
        # Now, assign new ones
        
        foreach my $g (@Genres) {
            my $Genre = $c->model('DB::DBTitlesToGenres')->create({
                active => 1,
                from_title_edit => $NewTitle->id,
                db_title_id => $title_id,
                db_genre_id => $g,
            });
        }
        
        
    }
    
    # Clean relevant memcached entries
    
    WorldOfAnime::Controller::DAO_Anime::CleanTitleCache($c, $title_id);
       
    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $User->username . "\">" . $User->username . "</a> has edited ";
    $ActionDescription .= "<a href=\"/anime/" . $title_id . "/$pretty_title\">" . $c->req->params->{'english_title'} . "</a> ";
    $ActionDescription .= "in the anime <a href=\"/anime\">database</a>.";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $User, $ActionDescription, 24, $title_id);   


    # Send me an e-mail

    my $username = $User->username;
    my $subject       = "Anime Database - New Title Edited.";
    my $EnglishTitle  = $c->req->params->{'english_title'};
    my $Description   = $c->req->params->{'description'};
    
	my $body = <<EndOfBody;
$username has edited the following title in the Anime Database:
Show Title: $EnglishTitle
Description: $Description

See the full title here:
http://www.worldofanime.com/anime/$title_id/$pretty_title
EndOfBody

    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, $subject);
    
    
   $c->response->redirect("/anime/$title_id/$pretty_title");
   $c->detach();    
}



sub add_review_comment :Path('/anime/review/ajax/add_comment') :Args(1) {
    my ( $self, $c, $id ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a comment.");
    
    my $Review = $c->model('Reviews::AnimeReview');
    $Review->build( $c, $id );

    $Review->add_comment( $c ); 
    
    $c->response->body("ok");
}


sub load_comments :Path('/anime/review/ajax/load_comments') :Args(1) {
    my ( $self, $c, $id ) = @_;
    my $CommentsHTML;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    my $Comments = WorldOfAnime::Controller::DAO_Anime::GetReviewComments( $c, $id );
    
    while (my $com = $Comments->next) {
        my $com_id = $com->id;
        my $comment = WorldOfAnime::Controller::DAO_News::GetNewsArticleCommentCacheable( $c, $com_id);
        
        my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $com->user_id );
        
        my $filename   = $p->profile_image_name;
        my $username   = $com->written_by->username;
        my $createdate = $com->createdate;
        my $content    = $com->comment;
        
        my $postDate = WorldOfAnime::Controller::Root::PrepareDate($createdate, 1, $tz);        
        
        $CommentsHTML .= "<div class=\"comment\">\n";
        $CommentsHTML .= "<a href=\"/profile/$username\"><img src=\"/static/images/t80/$filename\"></a>\n";
        $CommentsHTML .= "<p class=\"article\">" . $content . "</p>\n";
        $CommentsHTML .= "<br clear=\"all\">\n";
        $CommentsHTML .= "<h2>Submitted by <a href=\"/profile/$username\">$username</a> on $postDate</h2><br />";
        $CommentsHTML .= "</div>\n";
    }
    
    $c->response->body($CommentsHTML);
}




__PACKAGE__->meta->make_immutable;

1;
