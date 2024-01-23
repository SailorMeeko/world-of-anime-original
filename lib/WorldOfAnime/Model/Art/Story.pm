package WorldOfAnime::Model::Art::Story;
use Moose;
use JSON;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'db_title_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'based_on_title' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'title' => (
  is => 'rw',
  isa => 'Str',
);

has 'pretty_title' => (
    is => 'rw',
    isa => 'Str',
);

has 'description' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'started_by' => (
    is => 'rw',
    isa => 'Int',
);

has 'started_by_user' => (
    is => 'rw',
    isa => 'Str',
);

has 'rating_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'story_mode' => (
    is => 'rw',
    isa => 'Int',
);

has 'publish' => (
    is => 'rw',
    isa => 'Int',
);

has 'chapters' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'createdate' => (
  is => 'rw',
  isa => 'DateTime',
);




sub build {
    my $self = shift;
    my ( $c, $id ) = @_;
    
    $self->empty();

    my $cid = "woa:art_story:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->title( $cached->title );
        $self->pretty_title( $cached->pretty_title );
        $self->description( $cached->description );
        $self->db_title_id( $cached->db_title_id );
        $self->started_by( $cached->started_by );
        $self->started_by_user( $cached->started_by_user );
        $self->based_on_title( $cached->based_on_title );
        $self->rating_id( $cached->rating_id );
        $self->story_mode( $cached->story_mode );
        $self->publish( $cached->publish );
        $self->chapters( $cached->chapters );
	$self->createdate( $cached->createdate );

    } else {

        my $Story = $c->model('DB::ArtStoryTitle')->find($id);

	if (defined($Story)) {
            
	    $self->id( $Story->id );
            $self->title( $Story->title );
            $self->pretty_title( $c->model('Formatter')->prettify( $Story->title ) );
            $self->description( $Story->description );
            $self->db_title_id( $Story->db_title_id );
            $self->started_by( $Story->started_by_user_id );
            $self->started_by_user( $Story->started_by->username );
            eval { $self->based_on_title( $Story->db_title_rel->english_title ); };
            $self->rating_id( $Story->rating_id );
            $self->story_mode( $Story->story_mode );
            $self->publish( $Story->publish );
	    $self->createdate( $Story->createdate );
            
            my $chapters;
            my $Chapters = $c->model('DB::ArtStoryChapter')->search({
                -and => [
                    story_id => $Story->id,
                    publish => 1,
                ]
                },{
        	  order_by  => 'chapter_num ASC',
        	});
        
            if ($Chapters) {
                while (my $chap = $Chapters->next) {
                    my $id              = $chap->id;
                    my $story_id        = $chap->story_id;
                    my $user_id         = $chap->user_id;
                    my $chapter_num     = $chap->chapter_num;
                    my $chapter_title   = $chap->chapter_title;
                    my $publish         = $chap->publish;                
                    my $createdate      = $chap->createdate;

                    push (@{ $chapters} , { 'id' => "$id", 'story_id' => "$story_id", 'user_id' => "$user_id", 'chapter_num' => "$chapter_num", 'chapter_title' => "$chapter_title", 'publish' => "$publish", 'createdate' => "$createdate" });
                }
            }        

            if ($chapters) { $self->chapters( to_json($chapters)); }
            

            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub update {
    my $self = shift;
    my ( $c ) = @_;

    my $id              = $self->id;
    
    my $title           = $c->req->params->{fiction_title};
    my $rating_id       = $c->req->params->{rating};
    my $title_id        = $c->req->params->{anime_title_id} || 0;
    my $description     = $c->req->params->{description};

    # If the 'existing' radio button is specifically checked to "original", then it will have a value of 0
    # If this happens, we need to force title_id to 0 to prevent it from keeping its old value
    
    my $existing        = $c->req->params->{existing};
    if ($existing == 0) { $title_id = 0 };
    
    my $Title = $c->model('DB::ArtStoryTitle')->find({ id => $id });
    $Title->update({
        db_title_id        => $title_id,
        rating_id          => $rating_id,
        title              => $title,
        description        => $description,
        modifydate         => undef,
    });
    
    $self->clear( $c );
    
    $self->build( $c, $id );
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;

    my $id = $self->id;
    my $cid = "woa:art_story:$id";
    $c->cache->remove($cid);
}

sub empty {
    my $self = shift;

    $self->title("");
    $self->pretty_title("");
    $self->description("");
    $self->db_title_id(0);
    $self->based_on_title("");
    $self->rating_id(0);
    $self->story_mode(0);
    $self->publish(0);
}

1;