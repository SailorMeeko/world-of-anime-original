package WorldOfAnime::Controller::DAO_Images;
use Moose;
use HTML::LinkExtractor;
use File::Remove 'remove';
use namespace::autoclean;
use Digest::MD5 qw(md5_base64);

BEGIN {extends 'Catalyst::Controller'; }


sub upload_image :Local {
    my ( $c, $upload, $justfilename, $location ) = @_;
    
    # User can optionally pass in their own filedir
    # If they don't, use default
    my $filedir  = $c->config->{uploadfiledir};

    if ($location) {
	# Our default location is the u directory, for uploads
	# If we pass in a location, use that instead
	$filedir =~ s/u/$location/;
    } else {
	$location = "u";
    }
    
    # Strip off anything before the final / in the filename
    if ($justfilename =~ /\\/) { $justfilename =~ s/(.*)\\(.*)/$2/; }        

    my $filename = WorldOfAnime::Controller::Helpers::Images::GenerateImageFilename($justfilename);
        
    my $filesize = $upload->size;
    my $filetype = $upload->type;

    my $fileloc = $filedir . $filename;
    my $copytodir = $c->config->{baseimagefiledir};
	
    # Check for file's existence
    until (!(-e $copytodir . "$location/$filename")) {
	$filename = WorldOfAnime::Controller::Helpers::Images::GenerateImageFilename($justfilename);
    }
	
    $upload->copy_to($copytodir . "$location/$filename");

    # Image Magick stuff, for figuring out width and height
        
    my $i = Image::Magick->new;
    $i->Read($copytodir . "$location/{$filename}[0]");

    my $width = $i->Get('columns');
    my $height = $i->Get('rows');
    
    WorldOfAnime::Controller::DAO_Images::create_thumb( $i, 175, $copytodir, $filename );
    WorldOfAnime::Controller::DAO_Images::create_thumb( $i, 80, $copytodir, $filename );


    # Now, remove root/ from the filedir before storing
    $filedir =~ s/^root\///;
        
    my $Image = $c->model("DB::Images")->create({
        user_id  => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
        filedir  => $filedir,
        filename => $filename,
        filetype => $filetype,
        filesize => $filesize,
        height   => $height,
        width    => $width,
        modify_date => undef,
        create_date => undef,
    });

    # Return the ID of this new image
    return $Image->id
}


sub create_thumb :Local {
    my ($i, $DesiredWidth, $copytodir, $filename ) = @_;

    my $width = $i->Get('columns');
    my $height = $i->Get('rows');

    my $ThumbImage  = $i;
    my $ThumbWidth  = $width;
    my $ThumbHeight = $height;

    if ($ThumbWidth > $DesiredWidth) {
	$ThumbHeight = int(($ThumbHeight / $ThumbWidth) * $DesiredWidth);
	$ThumbWidth = $DesiredWidth;

	$ThumbImage->Thumbnail(Width => $ThumbWidth,
			        Height => $ThumbHeight);
	}

    $ThumbImage->Write($copytodir . "t" . $DesiredWidth . "/$filename");    
}



sub create_thumb_s3 :Local {
    my ($i, $DesiredWidth, $filedir, $filename, $filetype, $bucket ) = @_;

    my $width = $i->Get('columns');
    my $height = $i->Get('rows');
    
    my $ThumbImage  = $i;
    my $ThumbWidth  = $width;
    my $ThumbHeight = $height;

    if ($ThumbWidth > $DesiredWidth) {
	$ThumbHeight = int(($ThumbHeight / $ThumbWidth) * $DesiredWidth);
	$ThumbWidth = $DesiredWidth;

	$ThumbImage->Thumbnail(Width => $ThumbWidth,
			        Height => $ThumbHeight);
	}
    
    my $temp_filename = WorldOfAnime::Controller::Helpers::Images::GenerateImageFilename($filename);

    $ThumbImage->Write($filedir . "/$temp_filename");
    $bucket->add_key_filename("t" . $DesiredWidth . "/$filename", "$filedir/$temp_filename", { content_type => "$filetype" });
    
    # Delete from tmp location
    
    remove("$filedir/$temp_filename");
}



sub upload_image_s3 :Local {
    my ( $c, $upload, $justfilename, $location ) = @_;

    my $s3 = $c->model('S3');
    
    # User can optionally pass in their own filedir
    # If they don't, use default
    my $filedir  = $c->config->{uploadtmpdir};

    # Strip off anything before the final / in the filename
    if ($justfilename =~ /\\/) { $justfilename =~ s/(.*)\\(.*)/$2/; }        

    my $filename = WorldOfAnime::Controller::Helpers::Images::GenerateImageFilename($justfilename);
        
    my $filesize = $upload->size;
    my $filetype = $upload->type;
	
    # Check for file's existence in Image database
    
    until (!(WorldOfAnime::Controller::DAO_Images::FileExists( $c, $filename ))) {
	$filename = WorldOfAnime::Controller::Helpers::Images::GenerateImageFilename($justfilename);
    }
	
    $upload->copy_to("$filedir/$filename");

    # Image Magick stuff, for figuring out width and height
        
    my $i = Image::Magick->new;
    $i->Read("$filedir/{$filename}[0]");

    my $width = $i->Get('columns');
    my $height = $i->Get('rows');

    # S3 stuff
    
    my $bucket = $s3->client->bucket( 'images.worldofanime.com' );
    $bucket->add_key_filename("u/$filename", "$filedir/$filename", { content_type => "$filetype" });
    
    WorldOfAnime::Controller::DAO_Images::create_thumb_s3( $i, 175, $filedir, $filename, $filetype, $bucket );
    WorldOfAnime::Controller::DAO_Images::create_thumb_s3( $i, 80, $filedir, $filename, $filetype, $bucket );

    
    my $Image = $c->model("DB::Images")->create({
        user_id  => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
	is_s3    => 1,
        filedir  => 'images.worldofanime.com/u',
        filename => $filename,
        filetype => $filetype,
        filesize => $filesize,
        height   => $height,
        width    => $width,
        modify_date => undef,
        create_date => undef,
    });
    
    # Delete the file from tmp location
    
    remove("$filedir/$filename");    
    

    # Return the ID of this new image
    return $Image->id
}


# Note that this method is full of nasty, horrible, highly proprietary stuff
# from a dark, old time.  Once we're fully converted to S3, get rid of it!
sub upload_local_image_s3 :Local {
    my ( $c, $filedir, $justfilename, $filetype ) = @_;
    my $has_thumbs = 1;
    
    #if ($filedir eq "static/images/u/") { $has_thumbs = 1; }
    
    my $tempdir  = $c->config->{uploadtmpdir}; # Will be used for generating thumbnails later
    
    if ($filedir eq "static/images/u/") { $filedir = "u"; }
    if ($filedir eq "static/images/backgrounds/profile/") { $filedir = "backgrounds/profile"; }
    if ($filedir eq "static/images/backgrounds/groups/") { $filedir = "backgrounds/groups"; }
    if ($filedir eq "static/images/news/") { $filedir = "news"; }
    
    my $orig_dir = $c->config->{baseimagefiledir} . $filedir;
    my $orig_file = $justfilename;
    
    my $orig = $orig_dir . "/" . $orig_file;

    my $s3 = $c->model('S3');
    
    # Strip off anything before the final / in the filename
    if ($justfilename =~ /\\/) { $justfilename =~ s/(.*)\\(.*)/$2/; }
    
    # Also strip off anything from before the first _ (to clean up the old practive of naming the files userid_FILENAME)
    
    if ($justfilename =~ /(.*)_(.*)/) { $justfilename =~ s/(.*?)_(.*)/$2/; }

    my $filename = WorldOfAnime::Controller::Helpers::Images::GenerateImageFilename($justfilename);

    # Check for file's existence in Image database
    
    until (!(WorldOfAnime::Controller::DAO_Images::FileExists( $c, $filename ))) {
	$filename = WorldOfAnime::Controller::Helpers::Images::GenerateImageFilename($justfilename);
    }
   
    # Image Magick stuff, for figuring out width and height
        
    my $i = Image::Magick->new;
    $i->Read("$orig_dir/{$orig_file}[0]");
    
    my $width = $i->Get('columns');
    my $height = $i->Get('rows');
   
    # S3 stuff
    
    my $bucket = $s3->client->bucket( 'images.worldofanime.com' );
    $bucket->add_key_filename("u/$filename", "$orig_dir/$orig_file", { content_type => "$filetype" });

    WorldOfAnime::Controller::DAO_Images::create_thumb_s3( $i, 175, $tempdir, $filename, $filetype, $bucket );
    WorldOfAnime::Controller::DAO_Images::create_thumb_s3( $i, 80, $tempdir, $filename, $filetype, $bucket );

    # Remove original file, along with and thumbs if they exist
    remove("$orig");
    
    if ($has_thumbs) {
	my $thumb1 = $c->config->{baseimagefiledir} . "t175/$orig_file";
	my $thumb2 = $c->config->{baseimagefiledir} . "t80/$orig_file";
	
	remove($thumb1);
	remove($thumb2);
    }

    return $filename;
}



# Fetch a cacheable user by id (cache by hashref)
sub GetCacheableGalleryImageByID :Local {
    my ( $c, $id ) = @_;
    my %image;
    my $image_ref;
    
    my $cid = "worldofanime:gallery_image:$id";
    $image_ref = $c->cache->get($cid);
    
    unless ($image_ref) {
	my $GalleryImage = $c->model('DB::GalleryImages')->find( {
		id => $id,
	    });
	
	if (defined($GalleryImage)) {

	    return undef unless ($GalleryImage->active);  # If this item is inactive, don't even return it
	    
	    # Check to make sure this image exists ...
	    my $Image = $c->model('DB::Images')->find( $GalleryImage->image_id );
	    return undef unless (defined($Image));  # ... and return undef if it doesn't
	    
	    $image{'id'}            = $GalleryImage->id;
	    $image{'active'}        = $GalleryImage->active;
	    $image{'owner'}         = $GalleryImage->image_gallery->user_galleries->username;
	    $image{'owner_id'}      = $GalleryImage->image_gallery->user_id;
	    $image{'gallery_id'}    = $GalleryImage->image_gallery->id;
	    $image{'show_all'}      = $GalleryImage->image_gallery->show_all;
	    $image{'inappropriate'} = $GalleryImage->image_gallery->inappropriate;
	    $image{'is_s3'}         = $GalleryImage->image_images->is_s3;
	    $image{'filedir'}       = $GalleryImage->image_images->filedir;
	    $image{'filename'}      = $GalleryImage->image_images->filename;
	    $image{'height'}        = $GalleryImage->image_images->height;
	    $image{'width'}         = $GalleryImage->image_images->width;
	    $image{'title'}         = $GalleryImage->title;
	    $image{'real_image_id'} = $GalleryImage->image_id;
	    $image{'description'}   = $GalleryImage->description;
	    $image{'create_date'}   = $GalleryImage->createdate;

   
	    # Try to get number of comments
	    my $Comments = $c->model('DB::GalleryImageComments')->search({
		gallery_image_id => $id,
	    });
	    
	    if ($Comments) {
		my $num = $Comments->count;
		$image{'num_comments'} = $num;
	    }
	
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%image, 2592000);
	
	
    } else {
	%image = %$image_ref;
    }
    
    
    # For now, always get num_views from DB, until we can figure a better way
    
    if ($image{'id'}) {
	my $I = $c->model('DB::GalleryImages')->find( { id => $id, });
        $image{'num_views'} = $I->num_views;
    }
    
    return \%image;
}


sub CountGalleryImages :Local {
    my ( $c, $gallery_id ) = @_;

    # Get the gallery
    
    my $Gallery = $c->model("DB::Galleries")->find({
        id      => $gallery_id,
    });    

    # Now, update the count on their gallery
    # Set memcached object for 30 days

    my $cid = "worldofanime:gallery_image_count:$gallery_id";

    my $Images = $c->model('DB::GalleryImages')->search({
	-and => [
		gallery_id => $gallery_id,
		active => 1,
	    ],
    });

    $Gallery->update({
        num_images => $Images
    });
    
    $c->cache->set($cid, $Images, 2592000);    
}


sub AdjustGalleryImages :Local {
    my ( $c, $gallery_id, $adjustment ) = @_;
    
    # Get the gallery
    
    my $Gallery = $c->model('Galleries::Gallery');
    $Gallery->build( $c, $gallery_id );

    my $num_images = $Gallery->num_images;
    $num_images += $adjustment;

    $Gallery->update_image_count( $c, $num_images );
}


sub FileExists :Local {
    my ( $c, $filename ) = @_;
    
    my $Image = $c->model("DB::Images")->find({
	filename => $filename,
    });
    
    if (defined($Image)) {
	if ($Image->id) {
	    return $Image->id;
	}
    }
    
    return 0;    
}


sub IsImageUsed :Local {
    my ( $c, $image_id ) = @_;
    
    # This method is used to determine if a given image_id is needed anymore, or if it can be deleted
    # An image_id can be in...
    # gallery images (image_id)
    # group_gallery_images (image_id)
    # user_profile (profile_image_id, background_profile_image_id, banner_profile_image_id)
    # db_titles (anime_profile_image_id)
    # groups (groups_profile_image_id, groups_background_image_id)
    # news_articles (image_id)

    # Currently, this is only used for when a user updates their profile image, and it is used to make sure they
    # don't have that image in a gallery, since you can set a gallery image as your profile image
    # If we expand the image sharing uses, this needs to change
    
}


sub IsImagesApproved :Local {
    my ( $c, @ids ) = @_;
    
    @ids = grep { $_ != 0 } @ids;  # Remove 0
    
    my $count = $c->model('DB::Images')->search({
	-and => [
	    id => {
                'in' => [ @ids ]
	    },
		is_appropriate => { '!=' => 1, }
	    ]
    });

    # This query returns the count of the number of images in this list are not is_appropriate = 1
    # if $count = 0, then all images have been marked as appropriate, and you can return 1 (these images are approved)
    
    if ($count == 0) {
	return 1;
    } else {
	return 0;
    }
}


sub IsExternalImagesApproved :Path('/images/verify') {
    my ( $self, $c ) = @_;
    my $is_verified = 1;
    
    my @images = split(/,/, $c->req->param('images'));
    
    foreach my $i (@images) {
	if (!(($i =~ /^http:\/\/images\.worldofanime\.com/) ||
	      ($i =~ /\/static\//))) {
	    
		# This image is not from our site, see if it is ok
		
		if (!( VerifyExternalImage($c, $i) )) {
		    $is_verified = 0;
		}
	}
    }
    
    $c->response->body($is_verified);
}


sub IsExternalLinksApprovedPreRender :Local {
    my ( $c, $html ) = @_;
    my $is_verified = 1;
    my @images;
    my @links;
    
    my $LinkExtractor = new HTML::LinkExtractor();
    $LinkExtractor->parse(\$html);

    for my $link (@{$LinkExtractor->links}) {
	if ($link->{tag} eq "img") {
	    if (!(($link->{src} =~ /^http:\/\/images\.worldofanime\.com/) || ($link->{src} =~ /static\//))) {
	        push (@images, $link->{src});
	    }
	}
	
	if ($link->{tag} eq "a") {
	    if (!(($link->{href} =~ /^\//) || ($link->{href} =~ /^#/))) {	    
	        push (@links, $link->{href});
	    }
	}
    }
    
    for my $link (@links) {
	if (!( VerifyExternalLink($c, $link) )) {
	    $is_verified = 0;

	    # As soon as you find 1 that is not verified, we're done
	    return $is_verified;
	}	
    }
   
    for my $image (@images) {
	if (!( VerifyExternalImage($c, $image) )) {
	    $is_verified = 0;

	    # As soon as you find 1 that is not verified, we're done
	    return $is_verified;
	}
    }

    return $is_verified;
}


sub VerifyExternalImage :Local {
    my ( $c, $image ) = @_;
    my $approved;
    # 1 = approved
    # 2 = not approved
    # 0 = not reviewed yet
    
    my $cid = md5_base64("woa:external_image:$image");

    # Check cache
    
    $approved = $c->cache->get($cid);

    if ($approved eq 1) { return 1; }
    if ($approved eq 2) { return 0; } # 2 means explicitly not approved
    if ($approved eq 0) { return 0; } # 0 means not reviewed yet, which also means not approved
 
    # Don't know if this is approved yet, find its value, cache it, and return it

    my $ExternalImage = $c->model("DB::ExternalImages")->find({
        url => $image,
    });

    if ($ExternalImage) {
	my $IsApproved = $ExternalImage->is_approved;
    
	$c->cache->set($cid, $IsApproved, 2592000);
	return $IsApproved;
    } else {
	# Image doesn't exist yet, create it and return 0
	
	eval { my $ExternalImage = $c->model("DB::ExternalImages")->create({ url => $image, }) };
	return 0;
    }
}


sub VerifyExternalLink :Local {
    my ( $c, $link ) = @_;
    my $approved;
    # 1 = approved
    # 2 = not approved
    # 0 = not reviewed yet
    
    my $cid = md5_base64("woa:external_link:$link");

    # Check cache
    
    $approved = $c->cache->get($cid);
    
    if ($approved eq 1) { return 1; }
    if ($approved eq 2) { return 0; } # 2 means explicitly not approved
    if ($approved eq 0) { return 0; } # 0 means not reviewed yet, which also means not approved
 
    # Don't know if this is approved yet, find its value, cache it, and return it

    my $ExternalLink = $c->model("DB::ExternalLinks")->find({
        url => $link,
    });

    if ($ExternalLink) {
	my $IsApproved = $ExternalLink->is_approved;
    
	$c->cache->set($cid, $IsApproved, 2592000);
	return $IsApproved;
    } else {
	# Image doesn't exist yet, create it and return 0
	
	eval { my $ExternalLink = $c->model("DB::ExternalLinks")->create({ url => $link, }) };
	return 0;
    }
}


sub CleanGalleryImage :Local {
    my ( $c, $id ) = @_;
    
    $c->cache->remove("worldofanime:gallery_image:$id");
    $c->cache->remove("worldofanime:gallery_image_views:$id");
    $c->cache->remove("woa:gallery_image:$id");
    $c->cache->remove("woa:gallery_image_num_comments:$id");
    $c->cache->remove("woa:gallery_image_num_views:$id");
}


__PACKAGE__->meta->make_immutable;

1;