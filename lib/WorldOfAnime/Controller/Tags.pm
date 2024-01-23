package WorldOfAnime::Controller::Tags;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


sub search_tags :Path('/tag') :Args(1) {
    my ( $self, $c, $tag ) = @_;
    my $GalleryImageHTML;

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    # Get the tag_id
    
    my $tag_id = WorldOfAnime::Controller::DAO_Tags::GetTagID( $c, $tag );
    
    # Gallery Images
    
    my $gallery_images;
    my $gallery_images_json = WorldOfAnime::Controller::DAO_ImageTags::GetTaggedGalleryImages_JSON( $c, $tag_id );
    if ($gallery_images_json) { $gallery_images = from_json( $gallery_images_json ); }
    
    if ($gallery_images) {
        foreach my $gi (reverse @{ $gallery_images}) {
            
            my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $gi->{gallery_image_id} );
            
            my $image_id  = $i->{'id'};
            my $owner     = $i->{'owner'};
            my $owner_id  = $i->{'owner_id'};
            my $filedir   = $i->{'filedir'};
            my $filename  = $i->{'filename'};
            my $height    = $i->{'height'};
            my $width     = $i->{'width'};
            my $num_views = $i->{'num_views'};
            my $title     = $i->{'title'};
            my $show_all  = $i->{'show_all'};
            my $description  = $i->{'description'};
            my $num_comments = $i->{'num_comments'};
            my $create_date  = $i->{'create_date'};
            my $displayDate  = WorldOfAnime::Controller::Root::PrepareDate($create_date, 1, $tz);
            
            # If this gallery is not set to show_all, and you are not their friend, don't show this image
            
            unless ($show_all) {
                next unless ($user_id);  # Never show if a user is not logged in
                
                my $friend_status = WorldOfAnime::Controller::DAO_Friends::GetFriendStatus( $c, $user_id, $owner_id);
                
                next unless ($friend_status == 2);
            }

            $filedir =~ s/u\/$/t80\//;

            my $mult    = ($height / 80);
            my $new_height = int( ($height/$mult) / 1.1 );
            my $new_width  = int( ($width/$mult) /1.1);					

            my $hover_title = $title;
            $hover_title .= "<br>From " . $owner . "'s image gallery";
            $hover_title .= "<br>$num_views views";
            $hover_title .= "<br>$num_comments comments";
            $hover_title =~ s/\"/\'/g;

            $GalleryImageHTML .= "<a href=\"/profile/$owner/images/$image_id\" class=\"hoverable_box\" image_desc=\"$hover_title\"><img id=\"hover_info\" class=\"hoverable_image\" src=\"/$filedir$filename\" border=\"0\" width=\"$new_width\" height=\"$new_height\" alt=\"$title\"></a>\n";
        }
    }
    
    $c->stash->{gallery_images} = $GalleryImageHTML;
    $c->stash->{tag}      = $tag;
    $c->stash->{template} = 'tags/tagged_items.tt2';
}

__PACKAGE__->meta->make_immutable;

1;
