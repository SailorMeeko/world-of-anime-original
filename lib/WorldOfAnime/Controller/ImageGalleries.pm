package WorldOfAnime::Controller::ImageGalleries;
use Moose;
use JSON;
use namespace::autoclean;
use List::MoreUtils qw(uniq);

BEGIN {extends 'Catalyst::Controller'; }


sub view_all_image_galleries :Local {
    my ( $self, $c, $user, $action ) = @_;
    my $Images;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $is_admin = ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) ? 1 : 0;
    
    # Try to get a user profile

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $user_id         = $u->{'id'};
    
    # Is this yourself looking at this?
    
    my $is_self = ($user_id == $viewer_id) ? 1 : 0;
    
    # Get (your) friendship status
    
    my $friend_status = WorldOfAnime::Controller::DAO_Friends::GetFriendStatus( $c, $viewer_id, $user_id);

    my $Galleries = $c->model('Galleries::UserGalleries');
    $Galleries->build( $c, $user_id );
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff    
    
    $c->stash->{galleries}   = $Galleries;    
    $c->stash->{user}        = $u;
    $c->stash->{is_self}     = $is_self;
    $c->stash->{friend_status} = $friend_status;
    $c->stash->{is_admin}   = $is_admin;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'profile/view_all_galleries.tt2';
}


sub view_single_image_gallery :Local {
    my ( $self, $c, $user, $action, $gallery_id ) = @_;
    
    my $page = $c->req->params->{'page'} || 1;    

    my $Gallery;
    my $Images;
    my $ImagesHTML;
    my $ThumbsHTML;
    my $is_self;
    my $pager;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID         = $u->{'id'};
    
    # Is this yourself looking at this?
    
    if ($UserID == $viewer_id) { $is_self = 1; }


    # Get (your) friendship status
    
    my $friend_status = WorldOfAnime::Controller::DAO_Friends::GetFriendStatus( $c, $viewer_id, $UserID);


    # If the viewer is the owner of this gallery, show them the add link
    
    if ($viewer_id == $UserID) {
        $c->stash->{add_image_link} = "add_image";
    }


    # Get this gallery

    $Gallery = $c->model("DB::Galleries")->find({
	id => $gallery_id
    });

    # If this person is not your friend, and this user does not have show_gallery_to_all in their profile,
    # then don't even bother getting images

    # If there is no gallery, quit!
	
	unless ($Gallery) {
	    $c->stash->{error_message} = "This gallery doesn't exist.  It may have been deleted by its owner.";
	    $c->stash->{template}    = 'error_page.tt2';
	    $c->detach();
	}
    
    # If this is not the users gallery, quit!
	
	if ($Gallery->user_id != $UserID) {
	    $c->stash->{error_message} = "Funny, this gallery doesn't belong to this user.  How did you get here, anyway?";
	    $c->stash->{template}    = 'error_page.tt2';
	    $c->detach();
	}


        # Now, get this users images
        
        if ($gallery_id) {
            $Images = $c->model("DB::GalleryImages")->search({
                gallery_id => $gallery_id,
                active     => 1,
            },{
            	order_by => 'createdate DESC',
      				page      => "$page",
      				rows      => 36,
      			});
    			$pager = $Images->pager();
       }
        
				# A caveat, if this profile has been set to "inappropriate", then require the user to be your friend to see it        

				if ($Gallery) {
					if ( ($Gallery->inappropriate) && ($friend_status != 2) && !($is_self) && ($viewer_id != 3) ) {
    	    	undef ($Images);
		$c->stash->{error_message} = "This Image Gallery has been flagged as containing inappopriate images.  You must be this person's friend to view theis Image Gallery";
		$c->stash->{template}    = 'error_page.tt2';
		$c->detach();		
      	  }
					if ( !($Gallery->show_all) && ($friend_status != 2) && !($is_self) && ($viewer_id != 3) ) {
    	    	undef ($Images);
		$c->stash->{error_message} = "You must be this person's friend to view this Image Gallery";
		$c->stash->{template}    = 'error_page.tt2';
		$c->detach();		
      	  }
			
			    if ($Images) {

				$c->stash->{pager}    = $pager;
		
				while (my $image = $Images->next) {
				    
					my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $image->id );
					next unless (defined($i));
					
					my $image_id  = $i->{'id'};
                                        
                                        my $image = $c->model('Images::Image');
                                        $image->build($c, $i->{real_image_id});
                                        
                                        my $image_url = $image->small_url;
                                        
					my $filedir   = $i->{'filedir'};
					my $filename  = $i->{'filename'};
					my $height    = $i->{'height'};
					my $width     = $i->{'width'};
					my $num_views = $i->{'num_views'};
					my $title     = $i->{'title'};
					my $description  = $i->{'description'};
					my $num_comments = $i->{'num_comments'};
					my $create_date  = $i->{'create_date'};
					my $displayDate  = WorldOfAnime::Controller::Root::PrepareDate($create_date, 1, $tz);
					
					$filedir =~ s/u\/$/t80\//;
					
					my $mult    = ($height / 80);
					my $new_height = int( ($height/$mult) / 1.1 );
			                my $new_width  = int( ($width/$mult) /1.1);					
					
					my $hover_title = $title;
					$hover_title .= "<br>Added on $displayDate";
					$hover_title .= "<br>$num_views views";
					$hover_title .= "<br>$num_comments comments";
					$hover_title =~ s/\"/\'/g;
				
					$ImagesHTML .= "<a href=\"/profile/$user/images/$image_id\" class=\"hoverable_box\"><img id=\"hover_info\" class=\"hoverable_image\" src=\"$image_url\" border=\"0\" width=\"$new_width\" height=\"$new_height\"  image_desc=\"$hover_title\"></a>\n";
				}

			    }
        
    }
    

    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff            
        
    $c->stash->{user}        = $u;
    $c->stash->{images}      = $ImagesHTML;
    $c->stash->{thumbs}      = $ThumbsHTML;
    $c->stash->{is_self}     = $is_self;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{gallery}     = $Gallery;
    $c->stash->{template}    = 'profile/image_gallery.tt2';
}


sub view_image :Local {
    my ( $self, $c, $user, $action, $image_id ) = @_;
    my $show_image = 1;
    my $is_self;
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $CommentsHTML;
    my @image_ids;
    
    push (@image_ids, $image_id);
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    # Try to get a user profile

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $UserID         = $u->{'id'};
    push (@image_ids, $u->{'profile_image_id'}, $u->{'background_profile_image_id'});    

    # Is this yourself looking at this?
    
    if (($viewer_id) && ($UserID == $viewer_id)) { $is_self = 1; }


    # Have you blocked this user?
    my $IsBlock = WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $UserID, $viewer_id );
    if ($IsBlock) { $c->stash->{is_blocked} = 1; }  
    
    # Get (your) friendship status
    my $friend_status = WorldOfAnime::Controller::DAO_Friends::GetFriendStatus( $c, $viewer_id, $UserID);
        
    # Get this image
    
    my $Image = $c->model('Images::GalleryImage');
    $Image->build( $c, $image_id );
    
    my $active        = $Image->active;
    my $owner_id      = $Image->owner_id;
    my $gallery_id    = $Image->gallery_id;
    my $create_date   = $Image->createdate;
    my $displayDate   = WorldOfAnime::Controller::Root::PrepareDate($create_date, 1, $tz);    

    # Get info about the gallery
    
    my $Gallery = $c->model('Galleries::Gallery');
    $Gallery->build( $c, $gallery_id );	    

    my $inappropriate = $Gallery->inappropriate;
    my $show_all      = $Gallery->show_all;    
    
    # If this image is inactive
				
	unless ($active) {
	    $c->stash->{error_message} = "I can't find this image.  It might have been deleted by its owner.";
	    $c->stash->{template}      = 'error_page.tt2';
	    $c->detach();		    
	}
								

	# If this is not this persons image, then detach with error
				
	unless ($owner_id == $UserID) {
	    $c->stash->{error_message} = "What in the world???  That doesn't appear to be this person's image.";
	    $c->stash->{template}      = 'error_page.tt2';
	    $c->detach();	    
	}
	
	if ( ($inappropriate) && ($friend_status != 2) && !($is_self) && ($viewer_id != 3) ) {
	    $c->stash->{error_message} = "This person's Image Gallery has been flagged as containing inappopriate images.  You must be this person's friend to view their Image Gallery";
	    $c->stash->{template}      = 'error_page.tt2';
	    $c->detach();	    	    
	}


	if ( !($show_all) && ($friend_status != 2) && !($is_self) && ($viewer_id != 3) ) {
	    $c->stash->{error_message} = "You must be this person's friend to view this Image";
	    $c->stash->{template}      = 'error_page.tt2';
	    $c->detach();	    	    
	}
    
        # Now, increment the counter (unless it is me viewing)
	
        unless ( ($viewer_id) && ($viewer_id == 3) ) {
            $Image->record_view( $c );
        }

    
    
    # Get this users image galleries (so they can move it, if they want)
    # We can wrap memcached around this later
    
    my $GallerySelectionHTML;
    
    my $UserGalleries = $c->model('DB::Galleries')->search({
	user_id => $UserID,
    });
    
    while (my $ug = $UserGalleries->next) {
	$GallerySelectionHTML .= "<option value=\"" . $ug->id . "\" ";
	if ($ug->id == $gallery_id) { $GallerySelectionHTML .= "selected"; }
	$GallerySelectionHTML .= ">" . $ug->gallery_name . "</option>\n";
    }
    
    
    
    # Now, build image comments
    
    my $comments;
    my $comments_json = WorldOfAnime::Controller::DAO_Comments::GetGalleryImageComments_JSON( $c, $image_id );
    if ($comments_json) { $comments = from_json( $comments_json ); }

    if ($comments) {
	$CommentsHTML .= "<div id=\"posts\">\n";

	foreach my $ic (reverse @{ $comments}) {
	    
	    my $gc = WorldOfAnime::Controller::DAO_Comments::GetCacheableGalleryImageCommentByID( $c, $ic->{id});

	    my $commentor    = $gc->{'commentor'};
	    my $comment      = $gc->{'comment'};
	    my $comment_date = $gc->{'createdate'};
	    my $displayDate  = WorldOfAnime::Controller::Root::PrepareDate($comment_date, 1, $tz);
	    
	    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $commentor );
	    my $username   = $u->{'username'};

            my $p = $c->model('Users::UserProfile');
            $p->get_profile_image( $c,  $u->{'id'} );
            my $profile_image_id = $p->profile_image_id;
            
            my $i = $c->model('Images::Image');
            $i->build($c, $profile_image_id);
            my $profile_image_url = $i->thumb_url;
            
            push (@image_ids, $profile_image_id);
	    
	    
	    $CommentsHTML .= "<div id=\"individual_post\">\n";
	    $CommentsHTML .= "<table><tr>\n";
	    $CommentsHTML .= "<td valign=\"top\"><a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a></td>\n";
	    $CommentsHTML .= "<td valign=\"top\"><span class=\"post\">$comment</span></td></tr></table>\n";

	    $CommentsHTML .= "<span class=\"post_byline\">Posted by $username on $displayDate</span>\n";
	    $CommentsHTML .= "</div>\n";
	}
									       
	$CommentsHTML .= "</div>\n";
    }


    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff
    
    @image_ids = uniq(@image_ids);
    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids ) &&
                          WorldOfAnime::Controller::DAO_Images::IsExternalLinksApprovedPreRender( $c, $CommentsHTML );
    $c->stash->{is_self}     = $is_self;		
    $c->stash->{image}       = $Image;
    $c->stash->{user}        = $u;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{gallery_selection} = $GallerySelectionHTML;
    $c->stash->{gallery_id}  = $gallery_id;
    $c->stash->{show_image}  = $show_image;
    $c->stash->{metadisplaydate} = $displayDate;
    $c->stash->{comments_html} = $CommentsHTML;
    $c->stash->{template}    = 'profile/view_gallery_image.tt2';
}


sub add_gallery :Local {
    my ( $self, $c, $user, $action1, $action2 ) = @_;

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $user_id   = $u->{'id'};    

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($user_id == $viewer_id) {
	$c->stash->{error_message} = "You can't add a gallery for someone else.  How did you get here, anyway?";
	$c->stash->{template}    = 'error_page.tt2';
	$c->detach();
    }
    
    # If we got here, its ok to add gallery and redirect to main gallery page
    
    my $Gallery = $c->model('Galleries::Gallery');
    $Gallery->add_new( $c, $user_id );

    my $Galleries = $c->model('Galleries::UserGalleries');
    $Galleries->build( $c, $user_id );
    $Galleries->clear( $c );
        
    $c->response->redirect("/profile/$user/gallery");
}


sub delete_gallery :Local {
    my ( $self, $c, $user, $action, $gallery_id ) = @_;

    my $Gallery = $c->model('DB::Galleries')->find({
	id => $gallery_id,
    });
    
    # Detach if this is not the users gallery
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($Gallery->user_id == $user_id) {
	$c->stash->{error_message} = "Huh?  This isn't your gallery.  Wait, how did you get here?";
        $c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
    # First, find all images from this gallery and set them to active = 0
    
    my $Images = $c->model("DB::GalleryImages")->search({
        gallery_id => $gallery_id,
    });    	
        
    $Images->update({
        active => 0,
        modifydate => undef,
    });
    
    # Now delete the gallery
    
    $Gallery->delete;
    

    # Now, clear out the Latest Gallery Image cache, in case deleting this causes a new picture to show
        
    my $cid = "worldofanime:latest_gallery_image";
    $c->cache->remove($cid);
    
    my $Galleries = $c->model('Galleries::UserGalleries');
    $Galleries->build( $c, $user_id );
    $Galleries->clear( $c );    

    $c->response->redirect("/profile/$user/gallery");          
}


sub update_gallery :Local {
    my ( $self, $c, $user, $action, $gallery_id ) = @_;
    
    my $Gallery = $c->model('Galleries::Gallery');
    $Gallery->build( $c, $gallery_id );

    # Detach if this is not the users gallery
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($Gallery->user_id == $viewer_id) {
	$c->stash->{error_message} = "Huh?  This isn't your gallery.  Wait, how did you get here?";
        $c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
    
    $Gallery->update( $c );
    
    # Now, clear out the Latest Gallery Image cache, in case changing this causes a new picture to show
        
    my $cid = "worldofanime:latest_gallery_image";
    $c->cache->remove($cid);
    
    # Now, expire all the images in this gallery from cacheable images
    
    my $Images = $c->model('DB::GalleryImages')->search({
	gallery_id => $gallery_id,
    });
    
    if ($Images) {
	while (my $i = $Images->next) {
	    WorldOfAnime::Controller::DAO_Images::CleanGalleryImage( $c, $i->id );
	}
    }

    $c->response->redirect("/profile/$user/gallery");          
}



sub add_image :Local {
    my ( $self, $c, $user, $action, $gallery_id ) = @_;
    my $body;
    my $Email;
    
    # Try to get a user profile

    my $User = $c->model("DB::Users")->find({
        username => $user
    });

    my $UserID = $User->id;

    # Build this gallery
    
    my $Gallery = $c->model('Galleries::Gallery');
    $Gallery->build( $c, $gallery_id );
    
    # Make sure this is this users gallery
    
    
    # Handle image uploads

    if ($c->req->params->{image}) {
	
	my $image_title = $c->req->params->{image_title};
	my $image_desc  = $c->req->params->{image_description};
	
        # First, upload it and create an Image entry for it
	
	my $upload   = $c->req->upload('image');
        my $filename = $upload->filename;
        
        my $image_id = WorldOfAnime::Controller::DAO_Images::upload_image_s3( $c, $upload, $filename);	

        # Now, create a gallery image
        
        my $GalleryImage = $c->model("DB::GalleryImages")->create({
            gallery_id  => $gallery_id,
            image_id    => $image_id,
            num_views   => 0,
            active      => 1,
	    title       => $image_title,
	    description => $image_desc,
            modifydate  => undef,
            createdate  => undef,
        });
	
	# Now, clear out the Latest Gallery Image cache, in case this was being shown on the homepage
        
	my $cid = "worldofanime:latest_gallery_image";
	$c->cache->remove($cid);
        
        # Remove this galleries latest image
        $c->cache->remove("woa:gallery:latest_image:$gallery_id");

	my $GalleryImageID = $GalleryImage->id;
	
	# Add Gallery Image Count
	WorldOfAnime::Controller::DAO_Images::AdjustGalleryImages( $c, $gallery_id, 1 );

	### Create User Action
    
        my $ActionDescription = "<a href=\"/profile/" . $user . "\">" . $user . "</a> posted a ";
        $ActionDescription   .= "<a href=\"/profile/" . $user . "/images/" . $GalleryImage->id . "\">new image</a> in their image gallery";
    
        my $UserAction = $c->model("DB::UserActions")->create({
        	user_id => $UserID,
        	action_id => 3,
        	action_object => $GalleryImageID,
        	description => $ActionDescription,
        	modify_date => undef,
        	create_date => undef,
        });

        ### End User Action
	
	
	# Email friends
	my $to_email;
	my $from_email = '<meeko@worldofanime.com> World of Anime';
	my $subject = "$user has uploaded a new image.";    
    
	my $HTMLUsername = $user;
	$HTMLUsername =~ s/ /%20/g;

	$body = <<EndOfBody;
Your friend $user has uploaded a new image to their image gallery

You can see it at http://www.worldofanime.com/profile/$HTMLUsername/images/$GalleryImageID

To stop receiving these notices, log on to your profile at http://www.worldofanime.com/ and change your preference by unchecking "When a friend uploads a new image" under Notifications.
EndOfBody
    
	my $friends;
	my $friends_json = WorldOfAnime::Controller::DAO_Friends::GetFriends_JSON( $c, $UserID );
	if ($friends_json) { $friends = from_json( $friends_json ); }

	foreach my $f (@{ $friends}) {
	
	    my $e = WorldOfAnime::Controller::DAO_Users::GetCacheableEmailNotificationPrefsByID( $c, $f->{id} );
    
	    if ($e->{friend_upload_image}) {
	    
	        push (@{ $to_email}, { 'email' => $f->{email} });
	    
	}
	
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $f->{id}, "<a href=\"/profile/$user\">$user</a> has uploaded a <a href=\"/profile/$HTMLUsername/images/$GalleryImageID\">new image</a>.", 2);
	}  

	if ($to_email) {
	    WorldOfAnime::Controller::DAO_Email::StageEmail($c, $from_email, $subject, $body, to_json($to_email));	    
        }    

    }
        

    $c->response->redirect("/profile/$user/gallery/$gallery_id");      
}


sub update_image :Local {
    my ( $self, $c, $user, $action, $id ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to edit an image.");

    my $image = $c->model('DB::GalleryImages')->find( {
	id => $id,
    });
    
    my $owner = $image->image_images->user_id;
    my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    unless ($UserID == $owner) {
	$c->stash->{error_message} = "Huh?  This isn't your image.  Wait, how did you get here?";
        $c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }
	
    
    # If they made it here, its ok to modify the image
    
    # Lets store the gallery_id, in case they changed it
    # we need to update the image count on new and old gallery
    
    my $old_gallery_id = $image->gallery_id;
    
    my $title = $c->req->params->{title};
    my $desc  = $c->req->params->{description};
    my $new_gallery_id = $old_gallery_id;
    
    if ($c->req->params->{move_to_gallery}) {
	$new_gallery_id = $c->req->params->{move_to_gallery};
    }

    $image->update({
	title => $title,
	description => $desc,
	gallery_id => $new_gallery_id,
    });
    
    # Did they update the gallery id?
    
    unless ($new_gallery_id == $old_gallery_id) {
	# Subtract 1 from old gallery, and add 1 to new gallery

	my $OldGallery = $c->model('Galleries::Gallery');
	$OldGallery->build( $c, $old_gallery_id );
	$OldGallery->update_image_count( $c, $OldGallery->num_images - 1);
	$OldGallery->clear( $c );
	$c->cache->remove("woa:gallery:latest_image:$old_gallery_id");
	
	my $NewGallery = $c->model('Galleries::Gallery');
	$NewGallery->build( $c, $new_gallery_id );
	$NewGallery->update_image_count( $c, $NewGallery->num_images + 1);
	$NewGallery->clear( $c );
	$c->cache->remove("woa:gallery:latest_image:$new_gallery_id");

    }
    
    WorldOfAnime::Controller::DAO_Images::CleanGalleryImage( $c, $id );
    
    $c->response->redirect("/profile/$user/images/$id"); 
}


sub delete_image :Local {
    my ( $self, $c, $user, $action1, $gallery_image_id, $action3 ) = @_;

    my $is_self;
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Try to get a user profile

    my $User = $c->model("DB::Users")->find({
        username => $user
    });

    my $UserID = $User->id;

    # Is this yourself looking at this?
    
    if ($UserID == $viewer_id) { $is_self = 1; }


    if ($is_self) {

        # Get this image
    
        my $Image = $c->model("DB::GalleryImages")->find({
            id => $gallery_image_id,
        });
        
        my $image_id = $Image->image_id;

	# Make sure this isn't the users profile image
	
	if ($User->user_profiles->profile_image_id == $Image->image_images->id) {
	    $c->stash->{error_message} = "This is your profile image, you can't delete it.";
	    $c->stash->{template}    = 'error_page.tt2';	    
	    $c->detach();
	}
	
        
        $Image->update({
        	active => 0,
        	modifydate => undef,
        });
	
        # Now, clear out the Latest Gallery Image cache, in case this was being shown on the homepage
        
	my $cid = "worldofanime:latest_gallery_image";
	$c->cache->remove($cid);
        
        
        # To accomodate the Next Image and Previous Image entries, we need to figure out the next_id and previous_id of the image we are deleting
        # We then need to delete the next_id and previous_id of each of those 2 images
        
        my $GalleryImage = $c->model('Images::GalleryImage');
        $GalleryImage->build( $c, $gallery_image_id );
        my $prev_id = $GalleryImage->previous_id;
        my $next_id = $GalleryImage->next_id;
        
        if ($prev_id) {
            $c->cache->remove("woa:gallery_image_prev:$prev_id");
            $c->cache->remove("woa:gallery_image_next:$prev_id");
        }
        
        if ($next_id) {
            $c->cache->remove("woa:gallery_image_prev:$next_id");
            $c->cache->remove("woa:gallery_image_next:$next_id");            
        }
	
	
	# Subtract Gallery Image Count
	WorldOfAnime::Controller::DAO_Images::AdjustGalleryImages( $c, $Image->gallery_id, -1 );
	
	# Clear this Image from cache
	WorldOfAnime::Controller::DAO_Images::CleanGalleryImage( $c, $gallery_image_id );
	
	my $gallery_id = $Image->gallery_id;
	$c->cache->remove("woa:gallery:latest_image:$gallery_id");
	
	# Remove all gallery image tags from this item
	my $ImageTags = $c->model('DB::GalleryImagesToTags')->search({
	    gallery_image_id => $gallery_image_id,
	});
	
	$ImageTags->delete;
	
        # Remove the image from the filesystem
        
	my $i = $c->model('Images::Image');
	$i->build($c, $image_id);
        $i->delete_image( $c );
        $i->clear( $c );
        
        $c->response->redirect("/profile/$user/gallery");  
    } else {

	    $c->stash->{error_message} = "Wait a minute, this isn't your image!  How did you get here?";
	    $c->stash->{template}      = 'error_page.tt2';	        
	    $c->detach();
    }
}


sub add_comment_image :Local {
    my ( $self, $c, $user, $action1, $image_id, $action3 ) = @_;
    my $body;
    my $Email;

    # Figure out where the comment goes

    my $User = $c->model("DB::Users")->find({
        username => $user
    });

    my $UserID = $User->id;

    my $comment = $c->req->param('comment');
    my $commentor_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    

		# Who is this from?
		
    my $From = $c->model("DB::Users")->find({
    	id => $commentor_id
    });
    
    my $FromUsername = $From->username;
    
    # Make sure they are on the right person's image
    
    my $Image = $c->model("DB::GalleryImages")->find({
        id => $image_id,
    });
    
    if (!($UserID == $Image->image_images->user_id )) {
	$c->stash->{error_message} = "Huh?  Somehow this isn't the right person's image.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }    
    
    # Have you blocked this user?
    if ( WorldOfAnime::Controller::DAO_Users::IsBlock( $c, $UserID, $commentor_id ) ) {
	$c->stash->{error_message} = "This user has blocked you from posting on their image gallery.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
    }        
   
    
    my $Comment = $c->model("DB::GalleryImageComments")->create({
        gallery_image_id => $image_id,
        comment_user_id => $commentor_id,
        comment         => $comment,
        modifydate      => undef,
        createdate      => undef,        
    });
    
    # Remove cached comments so new one shows
    WorldOfAnime::Controller::DAO_Comments::CleanGalleryImageComments( $c, $image_id );
    

		# Do they want to know about it?
		
		if ($User->user_profiles->notify_image_comment) {
		    
		my $HTMLUsername = $user;
		$HTMLUsername =~ s/ /%20/g;

	$body = <<EndOfBody;
You have received a new comment on an image in your Image Gallery!

To view your new comment, log in and go to http://www.worldofanime.com/profile/$HTMLUsername/images/$image_id

if you do not want to receive e-mail notifications when you receive a new image comment anymore, log in and update your Notification Settings in your profile at http://www.worldofanime.com/profile
EndOfBody
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $body, 'New Image Gallery Comment.');

		}

    ### Create User Action
    
    my $ActionDescription = "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> posted a comment on an ";
    $ActionDescription   .= "<a href=\"/profile/" . $user . "/images/" . $image_id . "\">image</a> in ";
    $ActionDescription   .= "<a href=\"/profile/" . $user . "\">" . $user . "'s</a> image gallery";
    
    my $UserAction = $c->model("DB::UserActions")->create({
       	user_id => $From->id,
       	action_id => 6,
       	action_object => $image_id,
       	description => $ActionDescription,
    	modify_date => undef,
        create_date => undef,
    });

    ### End User Action
    
    WorldOfAnime::Controller::Notifications::AddNotification($c, $UserID, "<a href=\"/profile/$FromUsername\">$FromUsername</a> commented on one of your <a href=\"/profile/$user/images/$image_id\">images</a>", 1);
    
    WorldOfAnime::Controller::DAO_Images::CleanGalleryImage( $c, $image_id );
	
    $c->response->redirect("/profile/$user/$action1/$image_id");  
}


__PACKAGE__->meta->make_immutable;

1;
