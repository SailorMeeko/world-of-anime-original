package WorldOfAnime::Model::Reviews::AnimeReview;
use Moose;
use JSON;

BEGIN { extends 'WorldOfAnime::Model::Reviews::Review' }

has 'db_title_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'rating' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'review' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);



sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:anime_review:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->db_title_id( $cached->db_title_id );
        $self->rating( $cached->rating );
        $self->user_id( $cached->user_id );
        $self->review( $cached->review );
        $self->reviewer( $cached->reviewer );
        $self->createdate( $cached->createdate );

    } else {

        my $Review  = $c->model('DB::DBTitleReviews')->find({ id => $id });

	if (defined($Review)) {
            
	    $self->id( $Review->id );
	    $self->db_title_id( $Review->db_title_id );
	    $self->rating( $Review->rating );
            $self->user_id( $Review->user_id );
            $self->review( $c->model('Formatter')->clean_html($Review->review) );
            $self->reviewer( $Review->written_by->username );
            $self->createdate( $Review->createdate );
           
            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub add {
    my ( $self, $c ) = @_;
    
    my $user_id  = $self->user_id;
    my $title_id = $self->db_title_id;
    
    my $rating = $self->rating;
    my $review = $self->review;
    
    my $Review = $c->model('DB::DBTitleReviews')->create({
        db_title_id => $title_id,
        user_id => $user_id,
        review => $review,
        rating => $rating,
        modifydate => undef,
        createdate => undef,
    });
    
    $self->id( $Review->id );
    
    # Create Action
    
    my $review_id = $self->id;
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    $user_id  = $u->{'id'};
    my $username = $u->{'username'};    
    
    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $title_id );
    
    my $pretty_title  = $Title->pretty_title;
    my $english_title = $Title->english_title;

    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has written a new ";
    $ActionDescription .= "<a href=\"/anime/$title_id/$pretty_title/review/$review_id\">review</a> of ";
    $ActionDescription .= "<a href=\"/anime/$title_id/$pretty_title\">$english_title</a>";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 32, $review_id);
    
    
    # Email friends, and send notifications
    my %Emailed;

    my $to_email;
    my $from_email = '<meeko@worldofanime.com> World of Anime';
    my $subject = "$username has written a new review.";

    my $body = <<EndOfBody;
Your friend $username has written a new review for $english_title

You can see it at http://www.worldofanime.com/anime/$title_id/$pretty_title/review/$review_id

To stop receiving these notices, log on to your profile at http://www.worldofanime.com/ and change your preference by unchecking "When a friend writes a new review" under E-mail Notifications.
EndOfBody
    
    my $friends;
    my $friends_json = WorldOfAnime::Controller::DAO_Friends::GetFriends_JSON( $c, $user_id );
    if ($friends_json) { $friends = from_json( $friends_json ); }

    foreach my $f (@{ $friends}) {
	
	my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $f->{id} );
    
	if ($e->{friend_new_review}) {

		push (@{ $to_email}, { 'email' => $f->{email} });
		
	$Emailed{$f->{email}} = 1;
	}
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $f->{id}, "<a href=\"/profile/" . $username . "\">" . $username . "</a> has written a new <a href=\"/anime/$title_id/$pretty_title/review/$review_id\">review of $english_title</a>.", 35);
    }
    
    if ($to_email) {
	WorldOfAnime::Controller::DAO_Email::StageEmail($c, $from_email, $subject, $body, to_json($to_email));	    
    }        
}


sub add_comment {
    my ( $self, $c ) = @_;
    
    my $review_id   = $self->id;
    my $reviewer    = $self->reviewer;
    my $reviewer_id = $self->user_id;
    my $db_title_id = $self->db_title_id;
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $user_id  = $u->{'id'};
    my $username = $u->{'username'};
    
    my $comment = $c->req->params->{comment};
    
    my $nc = $c->model('DB::DBTitleReviewComments')->create({
        db_title_review_id => $review_id,
        user_id => $user_id,
        comment => $comment,
        modifydate => undef,
        createdate => undef,
    });

    # Remove the cache entry for the number of comments    
    $c->cache->remove("woa:db_title_review_comments:$review_id");
    
    # Create Action
    
    my $Title = $c->model('Database::AnimeTitle');
    $Title->build( $c, $db_title_id );
    
    my $pretty_title  = $Title->pretty_title;
    my $english_title = $Title->english_title;

    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has commented on ";
    $ActionDescription .= "<a href=\"/anime/$db_title_id/$pretty_title/review/$review_id\">$reviewer\'s review</a> of ";
    $ActionDescription .= "<a href=\"/anime/$db_title_id/$pretty_title\">$english_title</a>";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 33, $review_id);
    
    # Try to add notification to original writer, if it isn't yourself
    
    unless ($reviewer_id == $user_id) {
        WorldOfAnime::Controller::Notifications::AddNotification($c, $reviewer_id, "<a href=\"/profile/" . $username . "\">" . $username . "</a> has commented on your <a href=\"/anime/$db_title_id/$pretty_title/review/$review_id\">review of $english_title</a>.", 1);
    }
    
}


sub get_comments {
    my ( $self, $c, $latest, $get_latest_id ) = @_;
    unless ($latest) { $latest = 0; }
    
    $self->comments("");
    $self->num_comments( "0" );

    my $id = $self->id;
    
    my $cid = "woa:db_title_review_comments:$id";
    my $cached = $c->cache->get($cid);

    if (defined($cached)) {

	$self->comments( $cached->comments );
        $self->num_comments( $cached->num_comments );
        
    } else {
        
        my $Comments = $c->model('DB::DBTitleReviewComments')->search({
            -and => [ db_title_review_id => $id,
                      id => { '>' => $latest },
                    ],
            }, {
            order_by => 'createdate DESC'
        });
        
        
        if (defined($Comments)) {
            
            my $results;
            my $count = 0;
            
	    while (my $com = $Comments->next) {
                                
                my $c_id       = $com->id;
                my $user_id    = $com->user_id;
		my $username   = $com->written_by->username;
		my $comment    = $c->model('Formatter')->clean_html($com->comment);
		my $createdate = $com->createdate;
	    
                push (@{ $results}, { 'id' => "$c_id", 'user_id' => "$user_id", 'username' => "$username", 'comment' => "$comment", 'createdate' => "$createdate" });
                $count++;
            }
                
            if ($results) {
                my $json_text = to_json($results);
                $self->comments( $json_text );
                $self->num_comments( $count );
		
		$c->cache->set($cid, $self, 2592000);
            }
            
        }

    }
    
}


sub from_user_title {
    my $self = shift;
    my ( $c, $user_id, $title_id ) = @_;
    
    $self->id(undef); # Make sure we start with an empty id
    
    # Set user_id and title_id
    
    $self->user_id( $user_id );
    $self->db_title_id( $title_id );

    my $Review = $c->model('DB::DBTitleReviews')->find({ db_title_id => $title_id, user_id => $user_id });
    
    if (defined($Review)) {
        $self->build( $c, $Review->id );
    } else {
    }
    
}


sub clear_comments {
    my $self = shift;
    my ( $c ) = @_;

    my $id = $self->id;
    my $cid = "woa:db_title_review_comments:$id";
    $c->cache->remove($cid);    
}

1;