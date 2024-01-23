package WorldOfAnime::Model::Database::AnimeTitle;
use Moose;
use JSON;

BEGIN { extends 'WorldOfAnime::Model::Database::Title' }


has 'num_episodes' => (
  is => 'rw',
  isa => 'Int',
);

has 'episode_length' => (
  is => 'rw',
  isa => 'Int',
);

has 'entered_by' => (
  is => 'rw',
  isa => 'Str',
);

has 'last_edited_by_username' => (
  is => 'rw',
  isa => 'Str',
);

has 'genres' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'type' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'reviews' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

# Ratings

has 'avg_rating' => (
    is => 'rw',
);

has 'num_ratings' => (
    is => 'rw',
    isa => 'Int',
);

has 'ratings_json' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'all_ratings' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);



sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:db_title:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->english_title( $cached->english_title );
        $self->japanese_title( $cached->japanese_title );
        $self->pretty_title( $cached->pretty_title );
        $self->genres( $cached->genres );
	$self->type( $cached->type );
        $self->description( $cached->description );
        $self->publish_year( $cached->publish_year );
        $self->num_episodes( $cached->num_episodes );
        $self->episode_length( $cached->episode_length );
        $self->profile_image_id( $cached->profile_image_id );
        $self->filedir( $cached->filedir );
	$self->filename( $cached->filename );
	$self->image_height( $cached->image_height );
	$self->image_width( $cached->image_width );
        $self->entered_by( $cached->entered_by );
        $self->last_edited_by_username( $cached->last_edited_by_username );

    } else {

        my $Title  = $c->model('DB::DBTitles')->find({ static_id => $id, active => 1 });

	if (defined($Title)) {
            
	    $self->id( $Title->static_id );
	    $self->english_title(  $c->model('Formatter')->clean_html($Title->english_title) );
	    $self->japanese_title( $c->model('Formatter')->clean_html($Title->japanese_title) );
            $self->pretty_title( $c->model('Formatter')->prettify($self->english_title) );
            $self->description( $Title->description );
            $self->publish_year( $Title->publish_year );
            $self->num_episodes( $Title->num_episodes );
            $self->episode_length( $Title->episode_length );
	    $self->profile_image_id( $Title->profile_image_id );
	    $self->filedir( $Title->anime_profile_image_id->filedir );
	    $self->filename( $Title->anime_profile_image_id->filename );
	    $self->image_height( $Title->anime_profile_image_id->height );
	    $self->image_width( $Title->anime_profile_image_id->width );
            $self->last_edited_by_username( $Title->started_by->username );
	    
	    eval { $self->type( $Title->category->name) };

            # Figure out who initially entered this title
            
            my $OrigTitle = $c->model('DB::DBTitles')->search(
                { static_id => $id },
                { order_by => 'createdate ASC' });
            
            my $o = $OrigTitle->next;
            $self->entered_by( $o->started_by->username );
            

            # Figure out what genres this belongs in
            # then save as json
            
            my $results;
            
            my $Genres = $c->model('DB::DBTitlesToGenres')->search( {
                -and => [ db_title_id => $self->id,
                          active => 1,
                        ]
                });
            
	    eval {
                if (defined($Genres)) {
                    while (my $g = $Genres->next) {
                                
                        my $g_id   = $g->genre_id->id;
                        my $g_name = $g->genre_id->name;
	    
                        push (@{ $results}, { 'id' => "$g_id", 'name' => "$g_name" });
                    }
                
                    if ($results) {
                        my $json_text = to_json($results);
                        $self->genres( $json_text );
                    }
		}
	    };
            
            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub get_reviews {
    my $self = shift;
    my ( $c ) = @_;
    
    $self->reviews(""); # Make sure reviews are empty before starting
    
    my $id = $self->id;
    
    my $cid = "woa:db_title_reviews:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

	$self->reviews( $cached->reviews );
    } else {

	my $Reviews = $c->model('DB::DBTitleReviews')->search({
	    db_title_id => $id,
	}, {
            order_by => 'createdate DESC'
        });
	
	if (defined($Reviews)) {
	    
	    my $results;
	    
	    while (my $r = $Reviews->next) {
		
                my $r_id       = $r->id;
                my $user_id    = $r->user_id;
		my $username   = $r->written_by->username;
		my $review     = $c->model('Formatter')->clean_html($r->review);
		my $rating     = $r->rating;
		my $modifydate = $r->modifydate;
		my $createdate = $r->createdate;
	    
                push (@{ $results}, { 'id' => "$r_id", 'user_id' => "$user_id", 'username' => "$username", 'review' => "$review", 'rating' => "$rating", 'modifydate' => "$modifydate", 'createdate' => "$createdate" });
            }
                
            if ($results) {
			    
                my $json_text = to_json($results);
                $self->reviews( $json_text );
		
		$c->cache->set($cid, $self, 2592000);
            }
	    
	}

    }
    
    $self->reviews();
}


sub get_ratings {
    my $self = shift;
    my ( $c ) = @_;
    
    $self->avg_rating(0); 
    $self->num_ratings(0);
    
    my $id = $self->id;
    
    my $cid = "woa:db_title_ratings:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

	$self->avg_rating( $cached->avg_rating );
	$self->num_ratings( $cached->num_ratings );
	$self->ratings_json( $cached->ratings_json );
	
    } else {
	
	my $avg_rating = 0;
	my $num_ratings = 0;
	my $sum_ratings;	

	# These are DBRatings ratings (without reviews)
        my $Ratings = $c->model('DB::DBRatings')->search({ db_title_id => $id });
        
        if ($Ratings) {
            while (my $r = $Ratings->next) {
                $num_ratings++;
                $sum_ratings += $r->rating;
            }
        }
	
	# Need to get Reviews Ratings as well

	my $Reviews = $c->model('DB::DBTitleReviews')->search( { db_title_id => $id });
	
	if ($Reviews) {
            while (my $r = $Reviews->next) {
                $num_ratings++;
                $sum_ratings += $r->rating;
            }	    
	}
	
	
        $avg_rating = ($num_ratings != 0) ? ($sum_ratings / $num_ratings) : 0;
	    
	$self->avg_rating( $avg_rating );
	$self->num_ratings( $num_ratings );

	my $results;	
        push (@{ $results}, { 'avg_rating' => "$avg_rating", 'num_ratings' => "$num_ratings" });

        if ($results) {
            my $json_text = to_json($results);
            $self->ratings_json( $json_text );
        }	
	
	$c->cache->set($cid, $self, 2592000);

    }

}


sub get_all_ratings {
    my $self = shift;
    my ( $c ) = @_;
    
    $self->all_ratings("");
    
    my $id = $self->id;
    
    my $cid = "woa:db_title_all_ratings:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

	$self->all_ratings( $cached->all_ratings );
	
    } else {
	
	my $results;

	# These are DBRatings ratings (without reviews)
        my $Ratings = $c->model('DB::DBRatings')->search({ db_title_id => $id });
        
        if ($Ratings) {
            while (my $r = $Ratings->next) {
		my $username = $r->rated_by->username;
		my $rating   = $r->rating;
		
		push (@{ $results}, { 'username' => "$username", 'rating' => "$rating" });
            }
        }
	
	# Need to get Reviews Ratings as well

	my $Reviews = $c->model('DB::DBTitleReviews')->search( { db_title_id => $id });
	
	if ($Reviews) {
            while (my $r = $Reviews->next) {
		my $username = $r->written_by->username;
		my $rating   = $r->rating;
		
		push (@{ $results}, { 'username' => "$username", 'rating' => "$rating" });
            }	    
	}

        if ($results) {
            my $json_text = to_json($results);
            $self->all_ratings( $json_text );
        }	
	
	$c->cache->set($cid, $self, 2592000);

    }

}


sub deactivate {
    my $self = shift;
    my ( $c ) = @_;
    
    my $Title = $c->model('DB::DBTitles')->find({ static_id => $self->id, active => 1 });

    if (defined($Title)) {
        $Title->update({
                active => 0
        });
    }
    
    $self->clear( $c );
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;

    my $id = $self->id;
    my $cid = "woa:db_title:$id";
    $c->cache->remove($cid);
}


sub clear_reviews {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;

    $c->cache->remove("woa:db_title_reviews:$id");  # Main Reviews String
    $c->cache->remove("woa:db_title_ratings:$id");  # Remove rating cache as well, since the title will have been rated
    $c->cache->remove("woa:db_title_all_ratings:$id");  # Remove all ratings list
    
    $self->reviews();
}




1;