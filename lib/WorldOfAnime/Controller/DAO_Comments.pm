package WorldOfAnime::Controller::DAO_Comments;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


########## Gallery Image Comments ##########

sub GetCacheableGalleryImageCommentByID :Local {
    my ( $c, $id ) = @_;
    my %comment;
    my $comment_ref;
    
    my $cid = "worldofanime:gallery_image_comment:$id";
    $comment_ref = $c->cache->get($cid);
    
    unless ($comment_ref) {
	my $Comment = $c->model('DB::GalleryImageComments')->find( {
		id => $id,
	    });
	
	if (defined($Comment)) {

	    $comment{'id'}               = $Comment->id;
            $comment{'gallery_image_id'} = $Comment->gallery_image_id;
            $comment{'commentor'}        = $Comment->comment_user_id;
            $comment{'comment'}          = $c->model('Formatter')->clean_html($Comment->comment);
            $comment{'createdate'}       = $Comment->createdate;

	
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%comment, 2592000);
	
	
    } else {
	%comment = %$comment_ref;
    }
    
    return \%comment;
}



sub GetGalleryImageComments_JSON :Local {
    my ( $c, $gallery_image_id ) = @_;
    my $comments;
    
    my $cid = "worldofanime:gallery_image_comments_json:$gallery_image_id";
    $comments = $c->cache->get($cid);

    unless ($comments) {
        my $Comments = $c->model('DB::GalleryImageComments')->search({
                gallery_image_id => $gallery_image_id,
        },{
	  order_by  => 'createdate ASC',
	  });
        
        if ($Comments) {
            while (my $ic = $Comments->next) {
                my $comment_id       = $ic->id;
                my $gallery_image_id = $ic->gallery_image_id;
                my $commentor        = $ic->comment_user_id;
                my $comment          = $c->model('Formatter')->clean_html($ic->comment);
                my $createdate       = $ic->createdate;

                push (@{ $comments} , { 'id' => "$comment_id" });
            }
        }

        # Set memcached object for 30 days
        $c->cache->set($cid, $comments, 2592000);
    }
    
    if ($comments) { return to_json($comments); }
}


sub CleanGalleryImageComments :Local {
    my ( $c, $gallery_image_id ) = @_;
    
    $c->cache->remove("worldofanime:gallery_image_comments_json:$gallery_image_id");
}


########## End Gallery Image Comments ##########

__PACKAGE__->meta->make_immutable;

1;
