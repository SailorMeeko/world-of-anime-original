package WorldOfAnime::Model::Images::GalleryImage;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'image_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'gallery_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'owner_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'num_views' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'num_comments' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'active' => (
    is => 'rw',
    isa => 'Int',
);

has 'previous_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'next_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'title' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'description' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'modifydate' => (
    is => 'rw',
    isa => 'Maybe[DateTime]',
);

has 'createdate' => (
    is => 'rw',
    isa => 'Maybe[DateTime]',
);


sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:gallery_image:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->image_id( $cached->image_id );
        $self->gallery_id( $cached->gallery_id );
        $self->owner_id( $cached->owner_id );
        $self->num_comments( $cached->num_comments );
        $self->active( $cached->active );
        $self->title( $cached->title );
        $self->description( $cached->description );
        $self->modifydate( $cached->modifydate );
        $self->createdate( $cached->createdate );
        
    } else {
        
        my $GalleryImage =  $c->model("DB::GalleryImages")->find($id);
        
        if (defined($GalleryImage)) {

            $self->id( $GalleryImage->id );
            $self->image_id( $GalleryImage->image_id );
            $self->gallery_id( $GalleryImage->gallery_id );
            $self->active( $GalleryImage->active );
            $self->owner_id( $GalleryImage->image_gallery->user_id );
            $self->title( $GalleryImage->title );
            $self->description( $GalleryImage->description );
            $self->modifydate( $GalleryImage->modifydate );
            $self->createdate( $GalleryImage->createdate );
            $c->cache->set($cid, $self, 2592000);                    
        }
    }
    
    # Set num_views
    
    $self->set_num_views( $c );
    
    # Set previous and next images

    $self->set_prev_next( $c );
    $self->set_num_comments( $c );
}


sub set_prev_next {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    my $gallery_id = $self->gallery_id;
    
    # Start empty
    $self->previous_id(0);
    $self->next_id(0);
    
    # Look in memcached
    
    my $cid_p = "woa:gallery_image_prev:$id";
    my $cid_n = "woa:gallery_image_next:$id";

    my $cached_p = $c->cache->get($cid_p);
    my $cached_n = $c->cache->get($cid_n);
    
    if ( (defined($cached_p)) && (defined($cached_n)) ) {
        $self->previous_id( $cached_p );
        $self->next_id( $cached_n );
    } else {
        
        my $PrevImage =  $c->model("DB::GalleryImages")->search( {
            -and => [
                id => { '<' => $id },
                gallery_id => $gallery_id,
                active => 1,
            ],
            },{
                rows      => 1,
                order_by  => 'id DESC',
            });
        
        eval {
        if (defined($PrevImage)) {
            my $i = $PrevImage->first;
            if ($i->id) {
                $self->previous_id( $i->id );
                $c->cache->set($cid_p, $i->id, 2592000);
            }
        }
        };
        

        my $NextImage =  $c->model("DB::GalleryImages")->search( {
            -and => [
                id => { '>' => $id },
                gallery_id => $gallery_id,
                active => 1,
            ],
            },{
                rows      => 1,
                order_by  => 'id ASC',
            });
        
        eval {
        if (defined($NextImage)) {
            my $i = $NextImage->first;
            if ($i->id) {
                $self->next_id( $i->id );
                $c->cache->set($cid_n, $i->id, 2592000);
            }
        }
        };

    }
    
}


sub set_num_comments {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    
    # Look in memcached
    
    my $cid = "woa:gallery_image_num_comments:$id";

    my $cached = $c->cache->get($cid);
    
    if ($cached) {
        $self->num_comments( $cached );
    } else {
        my $num_comments = 0;
        
        my $Comments = $c->model('DB::GalleryImageComments')->search({ gallery_image_id => $id });
        
        eval {
        if (defined($Comments)) {
            $num_comments = $Comments->count;
        }
        };
        
        $self->num_comments( $num_comments );
        
        $c->cache->set($cid, $num_comments, 2592000);
    }
    
}


sub set_num_views {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    
    # Look in memcached
    
    my $cid = "woa:gallery_image_num_views:$id";
    
    my $cached = $c->cache->get($cid);    

    if (defined($cached)) {
        
        # Set it in the object
        $self->num_views( $cached );
        
    } else {

        my $GalleryImage =  $c->model("DB::GalleryImages")->find($id);
        
        if (defined($GalleryImage)) {
            $self->num_views( $GalleryImage->num_views );
            $c->cache->set($cid, $GalleryImage->num_views, 2592000);
        }

    }
    
}

sub record_view {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    
    # Look in memcached, if there we need to up the count
    
    my $cid = "woa:gallery_image_num_views:$id";
    
    my $cached = $c->cache->get($cid);    

    if (defined($cached)) {
        
        # Add 1 more view to current value
        my $num_views = $cached;
        $num_views++;
        
        # Set it in the object
        $self->num_views( $num_views );
        
        # Set it back in cache
        $c->cache->set($cid, $num_views, 2592000);
        
    }
    
    # We always need to record the hit in the database
    
    my $Image = $c->model('DB::GalleryImages')->find({
	id => $id,
    });
    if ($Image) {
	$Image->update({
	    num_views => $Image->num_views + 1,
	});
    }    
    
}

__PACKAGE__->meta->make_immutable;

1;
