package WorldOfAnime::Controller::Favorites;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


sub view_favorites :Path('/favorites') :Args(0) {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your favorites.");

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    
    $c->stash->{user}   = $u;    
    $c->stash->{template} = 'favorites/main_favorites.tt2';
}

sub view_favorite_gallery_images :Path('/favorites/gallery_images') :Args(0) {
    my ( $self, $c ) = @_;
    my $ImagesHTML;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to view your favorites.");
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );

    my $images;
    my $images_json = WorldOfAnime::Controller::DAO_Favorites::GetGalleryImageFavorites_JSON( $c, $user_id );
    if ($images_json) { $images = from_json( $images_json ); }
    
    if ($images) {
    foreach my $fav_image (reverse @{ $images}) {

        my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $fav_image->{id} );

        my $image_id  = $i->{'id'};
        my $owner     = $i->{'owner'};
        my $filedir   = $i->{'filedir'};
        my $filename  = $i->{'filename'};
        my $height    = $i->{'height'};
        my $width     = $i->{'width'};
        my $num_views = $i->{'num_views'};
        my $title     = $i->{'title'};
        my $description  = $i->{'description'};
        my $num_comments = $i->{'num_comments'};
        my $create_date  = $i->{'create_date'};
        my $displayDate  = WorldOfAnime::Controller::Root::PrepareDate($fav_image->{createdate}, 1, $tz);

	my $Image = $c->model('Images::Image');
	$Image->build($c, $i->{real_image_id});
	my $image_url = $Image->small_url;

        my $mult    = ($height / 80) || 1;
        my $new_height = int( ($height/$mult) / 1.1 );
        my $new_width  = int( ($width/$mult) /1.1);					

        my $hover_title = $title;
        $hover_title .= "<br>From " . $owner . "'s image gallery";
        $hover_title .= "<br>Added to Favorites on $displayDate";
        $hover_title .= "<br>$num_views views";
        $hover_title .= "<br>$num_comments comments";
        $hover_title =~ s/\"/\'/g;

        $ImagesHTML .= "<a href=\"/profile/$owner/images/$image_id\" class=\"hoverable_box\"><img id=\"hover_info\" class=\"hoverable_image\" src=\"$image_url\" border=\"0\" width=\"$new_width\" height=\"$new_height\" image_desc=\"$hover_title\"></a>\n";
    }
    }

    $c->stash->{user}   = $u;
    $c->stash->{images} = $ImagesHTML;
    $c->stash->{template} = 'favorites/gallery_images.tt2';    
}



sub check_gallery_favorites :Path('/favorites/check_gallery_favorites') :Args(1) {
    my ( $self, $c, $gallery_image_id ) = @_;
    my $HTML;
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    if ($user_id) {
        
        # Is this on favorites?
        
        my $is_favorite = WorldOfAnime::Controller::DAO_Favorites::IsGalleryImageFavorite( $c, $gallery_image_id, $user_id );
        
        if ($is_favorite) {
            $HTML = "<a href=\"#\" onclick=\"javascript:return false\" class=\"share_button\" id=\"unfavorite_this\" gallery_image_id=\"$gallery_image_id\" >Remove from Favorites</a>";
        } else {
            $HTML = "<a href=\"#\" onclick=\"javascript:return false\" class=\"share_button\" id=\"favorite_this\" gallery_image_id=\"$gallery_image_id\" >Add to Favorites</a>";
        }
    
    }

    $c->response->body($HTML); 
}


sub add_gallery_image_favorites :Path('/favorites/add_gallery_image_favorite/') :Args(1) {
    my ( $self, $c, $gallery_image_id ) = @_;
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    WorldOfAnime::Controller::DAO_Favorites::AddGalleryImageFavorite( $c, $gallery_image_id, $user_id );
    WorldOfAnime::Controller::DAO_Favorites::CalcGalleryImageFavorites( $c, $user_id );
    
    my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $gallery_image_id );
    my $owner     = $i->{'owner'};
    my $owner_id  = $i->{'owner_id'};
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username   = $u->{'username'};    
    
    unless ($owner_id == $user_id) {  # Don't notify yourself
        WorldOfAnime::Controller::Notifications::AddNotification($c, $owner_id, "<a href=\"/profile/$username\">$username</a> has added one of your <a href=\"/profile/$owner/images/$gallery_image_id\">images</a> to their Favorites.", 30);
    }
    
    my $ActionDescription  = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has added one of <a href=\"/profile/" . $owner . "\">" . $owner . "'s</a> <a href=\"/profile/$owner/images/$gallery_image_id\">images</a> to their Favorites";

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $user_id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    $c->response->body(); 
}

sub remove_gallery_image_favorites :Path('/favorites/remove_gallery_image_favorite/') :Args(1) {
    my ( $self, $c, $gallery_image_id ) = @_;
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    WorldOfAnime::Controller::DAO_Favorites::RemoveGalleryImageFavorite( $c, $gallery_image_id, $user_id );
    WorldOfAnime::Controller::DAO_Favorites::CalcGalleryImageFavorites( $c, $user_id );

    my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $gallery_image_id );
    my $owner     = $i->{'owner'};
    my $owner_id  = $i->{'owner_id'};
    
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $user_id );
    my $username   = $u->{'username'};    
    
    unless ($owner_id == $user_id) {  # Don't notify yourself
        WorldOfAnime::Controller::Notifications::AddNotification($c, $owner_id, "<a href=\"/profile/$username\">$username</a> has removed one of your <a href=\"/profile/$owner/images/$gallery_image_id\">images</a> from their Favorites.", 31);
    }

    my $ActionDescription  = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has removed one of <a href=\"/profile/" . $owner . "\">" . $owner . "'s</a> <a href=\"/profile/$owner/images/$gallery_image_id\">images</a> from their Favorites";

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $user_id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    $c->response->body(); 
}


__PACKAGE__->meta->make_immutable;

1;
