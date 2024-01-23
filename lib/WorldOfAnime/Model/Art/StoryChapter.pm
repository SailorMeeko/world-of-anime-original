package WorldOfAnime::Model::Art::StoryChapter;
use Moose;
use JSON;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'story_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'chapter_num' => (
    is => 'rw',
    isa => 'Int',
);

has 'chapter_title' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'chapter_content' => (
    is => 'rw',
);

has 'publish' => (
    is => 'rw',
    isa => 'Int',
);

has 'createdate' => (
    is => 'rw',
    isa => 'DateTime',
);




sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:art_story_chapter:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {
        $self->id( $cached->id );
        $self->story_id ($cached->story_id );
        $self->user_id( $cached->user_id );
        $self->chapter_num( $cached->chapter_num );
        $self->chapter_title( $cached->chapter_title );
        $self->chapter_content( $cached->chapter_content );
        $self->publish( $cached->publish );
        $self->createdate( $cached->createdate );

    } else {
        my $Chapter = $c->model('DB::ArtStoryChapter')->find($id);
        
        if ($Chapter) {
            $self->id( $Chapter->id );
            $self->story_id( $Chapter->story_id );
            $self->user_id( $Chapter->user_id );
            $self->chapter_num( $Chapter->chapter_num );
            $self->chapter_title( $Chapter->chapter_title );
            $self->chapter_content( $c->model('Formatter')->clean_html($Chapter->chapter_content) );
            $self->publish( $Chapter->publish );
            $self->createdate( $Chapter->createdate );
        }
        
        $c->cache->set($cid, $self, 2592000);
    }
}


sub update {
    my $self = shift;
    my ( $c ) = @_;

    my $id              = $self->id;
    
    my $chapter_content = $c->model('Formatter')->clean_html($c->req->params->{content});
    my $chapter_title   = $c->req->params->{title};
    
    my $Chapter = $c->model('DB::ArtStoryChapter')->find($id);

    $Chapter->update({
        chapter_title      => $chapter_title,
        chapter_content    => $chapter_content,
        modifydate         => undef,
    });
    
    $self->clear( $c );
    
    # Gotta clear out the Story from cache too, as it holds chapter info in JSON format
    
    my $s = $c->model('Art::Story');
    $s->build( $c, $self->story_id );
    $s->clear( $c );
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;

    my $id = $self->id;
    my $cid = "woa:art_story_chapter:$id";

    $c->cache->remove($cid);
}

1;