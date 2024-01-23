package WorldOfAnime::Controller::DAO_Favorites;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


########## Still to do ##################

# We need to make sure people who add an image to Favorites should not see an image they shouldn't see

# For example, if someone changes a gallery from public to private, everyone who is not their friend who has
# images in that gallery in their favorites should have that image removed from favorites

# Also, if someone unfriends someone, we need to check to make sure they don't have any private images in
# their favorites

# Also, create an admin routine where we can clean these up


########## Gallery Image Stuff ##########
sub IsGalleryImageFavorite :Local {
    my ( $c, $gallery_image_id, $user_id ) = @_;
    my $is_favorite;
    
    my $cid = "worldofanime:favorite_gallery_image:$user_id:$gallery_image_id";
    $is_favorite = $c->cache->get($cid);
    
    unless ( defined($is_favorite) ) {
        
        my $Fav = $c->model('DB::FavoritesGalleryImages')->search({
            -and => [
                gallery_image_id => $gallery_image_id,
                user_id => $user_id,
            ],
        });
        
        if ($Fav->count > 0) {
            $is_favorite = 1;
        } else {
            $is_favorite = 0;
        }
        
	$c->cache->set($cid, $is_favorite, 2592000);        
    }
    
    return $is_favorite;
}


sub GetGalleryImageFavorites_JSON :Local {
    my ( $c, $id ) = @_;
    my $gallery_images;
    
    my $cid = "worldofanime:gallery_image_favorites:$id";
    $gallery_images = $c->cache->get($cid);

    unless ($gallery_images) {
        my $Favs = $c->model('DB::FavoritesGalleryImages')->search({
            user_id => $id,
        });
        
        if ($Favs) {
            while (my $f = $Favs->next) {
                my $image_id   = $f->gallery_image_id;
                my $createdate = $f->createdate;

                push (@{ $gallery_images} , { 'id' => "$image_id", 'createdate' => "$createdate" });
            }
        }

        # Set memcached object for 30 days
        $c->cache->set($cid, $gallery_images, 2592000);
    }
    
    if ($gallery_images) { return to_json($gallery_images); }
}


sub CalcGalleryImageFavorites :Local {
    my ( $c, $id ) = @_;
    my $gallery_images;
    
    my $cid = "worldofanime:gallery_image_favorites:$id";
    $c->cache->remove($cid);    

    my $Favs = $c->model('DB::FavoritesGalleryImages')->search({
        user_id => $id,
    });

    if ($Favs) {
        while (my $f = $Favs->next) {
            my $image_id   = $f->gallery_image_id;
            my $createdate = $f->createdate;

            push (@{ $gallery_images} , { 'id' => "$image_id", 'createdate' => "$createdate" });
        }
    }

    # Set memcached object for 30 days
    $c->cache->set($cid, $gallery_images, 2592000);
}



sub AddGalleryImageFavorite :Local {
    my ( $c, $gallery_image_id, $user_id ) = @_;
    
    my $cid = "worldofanime:favorite_gallery_image:$user_id:$gallery_image_id";
    
    my $Fav = $c->model('DB::FavoritesGalleryImages')->create({
        gallery_image_id => $gallery_image_id,
        user_id => $user_id,
        createdate => undef,
    });
    
    $c->cache->set($cid, 1, 2592000);
}


sub RemoveGalleryImageFavorite :Local {
    my ( $c, $gallery_image_id, $user_id ) = @_;
    
    my $cid = "worldofanime:favorite_gallery_image:$user_id:$gallery_image_id";
    
    my $Fav = $c->model('DB::FavoritesGalleryImages')->search({
        -and => [
            gallery_image_id => $gallery_image_id,
            user_id => $user_id,
        ],
    });

    $Fav->delete;
    
    $c->cache->remove($cid);
}
########## End Gallery Image Stuff ##########



__PACKAGE__->meta->make_immutable;

1;
