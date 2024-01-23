package WorldOfAnime::Controller::DAO_ImageTags;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


sub AddGalleryImageTag :Local {
    my ( $c, $user_id, $gallery_image_id, $tag_id ) = @_;

    my $is_tagged = eval {
        $c->model('DB::GalleryImagesToTags')->create({
            gallery_image_id => $gallery_image_id,
            tag_id => $tag_id,
            tagged_by => $user_id,
            create_date => undef,
        });
    };
    
    if ($is_tagged) {
        WorldOfAnime::Controller::DAO_ImageTags::CleanImageTags( $c, $gallery_image_id );
        WorldOfAnime::Controller::DAO_ImageTags::CleanTaggedItems( $c, $tag_id );        

        # Send notification to the image owner
        
        my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
        my $username   = $u->{'username'};    
        
        my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $gallery_image_id );
        my $owner     = $i->{'owner'};
        my $owner_id  = $i->{'owner_id'};
        my $show_all  = $i->{'show_all'};
        
        my $tag_name = WorldOfAnime::Controller::DAO_Tags::GetTagName( $c, $tag_id );
        
        unless ($owner_id == $user_id) {  # Don't notify yourself
            WorldOfAnime::Controller::Notifications::AddNotification($c, $owner_id, "<a href=\"/profile/$username\">$username</a> has tagged one of your <a href=\"/profile/$owner/images/$gallery_image_id\">images</a> with the tag <a href=\"/tag/$tag_name\">$tag_name</a>.", 32);
        }
        
        # Add Action (if the image is not in a private gallery)

        if ($show_all) {
    
            my $ActionDescription  = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has tagged one of <a href=\"/profile/" . $owner . "\">" . $owner . "'s</a> <a href=\"/profile/$owner/images/$gallery_image_id\">images</a> with the tag <a href=\"/tag/$tag_name\">$tag_name</a>.";

            my $UserAction = $c->model("DB::UserActions")->create({
                user_id => $user_id,
                description => $ActionDescription,
                modify_date => undef,
                create_date => undef,
            });
        }
        
    }
    
}



sub RemoveGalleryImageTag :Local {
    my ( $c, $user_id, $tag_id, $id ) = @_;

    my $ImageTag = $c->model('DB::GalleryImagesToTags')->find({ id => $id });
    
    $ImageTag->update({
        active => 0,
        untagged_by => $user_id,
        untagged_date => undef,
    });
    
    my $gallery_image_id = $ImageTag->gallery_image_id;

    WorldOfAnime::Controller::DAO_ImageTags::CleanImageTags( $c, $gallery_image_id );
    WorldOfAnime::Controller::DAO_ImageTags::CleanTaggedItems( $c, $tag_id );

    # Send notification to the image owner
        
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username   = $u->{'username'};    
        
    my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $gallery_image_id );
    my $owner     = $i->{'owner'};
    my $owner_id  = $i->{'owner_id'};
    my $show_all  = $i->{'show_all'};
        
    my $tag_name = WorldOfAnime::Controller::DAO_Tags::GetTagName( $c, $tag_id );
        
    unless ($owner_id == $user_id) {  # Don't notify yourself
        WorldOfAnime::Controller::Notifications::AddNotification($c, $owner_id, "<a href=\"/profile/$username\">$username</a> has removed the tag <a href=\"/tag/$tag_name\">$tag_name</a> from one of your <a href=\"/profile/$owner/images/$gallery_image_id\">images</a>.", 33);
    }
    
    # Add Action (if the image is not in a private gallery)
    
    if ($show_all) {
    
        my $ActionDescription  = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has removed the tag <a href=\"/tag/$tag_name\">$tag_name</a> from one of <a href=\"/profile/" . $owner . "\">" . $owner . "'s</a> <a href=\"/profile/$owner/images/$gallery_image_id\">images</a>.";

        my $UserAction = $c->model("DB::UserActions")->create({
            user_id => $user_id,
            description => $ActionDescription,
            modify_date => undef,
            create_date => undef,
        });
    }
    
}



sub GetGalleryImageTags_JSON :Local {
    my ( $c, $gallery_image_id ) = @_;
    my $tags;
    
    my $cid = "worldofanime:gallery_image_tags:$gallery_image_id";
    $tags = $c->cache->get($cid);

    unless ($tags) {
        my $Tags = $c->model('DB::GalleryImagesToTags')->search({
            -and => [
                gallery_image_id => $gallery_image_id,
                active => 1,
            ]
        },{
	  order_by  => 'create_date ASC',
	  });
        
        if ($Tags) {
            while (my $t = $Tags->next) {
                my $id         = $t->id;
                my $tag_id     = $t->tag_id;
                my $tag        = $t->tag->tag;
                my $tagged_by  = $t->tagged_by;
                my $createdate = $t->create_date;

                push (@{ $tags} , { 'id' => "$id", 'tag' => "$tag", 'tag_id' => "$tag_id", 'tagged_by' => "$tagged_by", 'createdate' => "$createdate" });
            }
        }

        # Set memcached object for 30 days
        $c->cache->set($cid, $tags, 2592000);
    }
    
    if ($tags) { return to_json($tags); }
}



sub GetTaggedGalleryImages_JSON :Local {
    my ( $c, $tag_id ) = @_;
    my $tagged_gallery_images;
    
    my $cid = "worldofanime:tagged_gallery_images:$tag_id";
    $tagged_gallery_images = $c->cache->get($cid);
    
    unless ($tagged_gallery_images) {
        my $GalleryImages = $c->model('DB::GalleryImagesToTags')->search({
            -and => [
                tag_id => $tag_id,
                active => 1,
            ],
        },{
	  order_by  => 'create_date ASC',
	  });
        
        if ($GalleryImages) {
            while (my $i = $GalleryImages->next) {
                my $id = $i->id;
                my $gallery_image_id = $i->gallery_image_id;
                
                push (@{ $tagged_gallery_images}, { 'id' => "$id", 'gallery_image_id' => $gallery_image_id });
            }
        }
        
        # Set memcached object for 30 days
        $c->cache->set($cid, $tagged_gallery_images, 2592000);
    }
    
    if ($tagged_gallery_images) { return to_json($tagged_gallery_images); }
}


sub CleanImageTags :Local {
    my ( $c, $gallery_image_id ) = @_;
    
    $c->cache->remove("worldofanime:gallery_image_tags:$gallery_image_id");
}


sub CleanTaggedItems :Local {
    my ( $c, $tag_id ) = @_;
    
    $c->cache->remove("worldofanime:tagged_gallery_images:$tag_id");
}

__PACKAGE__->meta->make_immutable;

1;
