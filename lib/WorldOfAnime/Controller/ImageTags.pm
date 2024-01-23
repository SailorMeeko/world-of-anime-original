package WorldOfAnime::Controller::ImageTags;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


sub AddGalleryImageTag :Path('/tags/gallery/images/add') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add an image tag.");    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $gallery_image_id = $c->req->params->{'gallery_image_id'};
    my $tag              = $c->req->params->{'tag'};
    
    # Get the tag_id
    
    my $tag_id = WorldOfAnime::Controller::DAO_Tags::GetTagID( $c, $tag );
    
    # Try to add tag to image
    
    WorldOfAnime::Controller::DAO_ImageTags::AddGalleryImageTag( $c, $user_id, $gallery_image_id, $tag_id );
    
    $c->response->body(); 
}


sub RemoveGalleryImageTag :Path('/tags/gallery/images/remove') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to remove an image tag.");    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    my $tag              = $c->req->params->{'tag'};
    my $id               = $c->req->params->{'tag_id'};
    
    # Get the tag_id
    
    my $tag_id = WorldOfAnime::Controller::DAO_Tags::GetTagID( $c, $tag );
    
    # Remove the tag
    
    WorldOfAnime::Controller::DAO_ImageTags::RemoveGalleryImageTag( $c, $user_id, $tag_id, $id );
    
    $c->response->body(); 
}


sub populate_tags :Path('/tags/gallery/images/fetch') :Args(1) {
    my ( $self, $c, $gallery_image_id ) = @_;
    my $allow_delete = 0;   
    my $HTML = "tags | ";
    my $del_style;

    $del_style = "style=\"font-size: 11px; color: grey;\"";
    
    # Should we allow these tags to be deleted?
    # For now, only allow an images owner to delete tags
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $gallery_image_id );
    my $owner_id  = $i->{'owner_id'};
    
    if (($user_id) && ($user_id == $owner_id)) {
        $allow_delete = 1;
    }

    my $tags;
    my $tags_json = WorldOfAnime::Controller::DAO_ImageTags::GetGalleryImageTags_JSON( $c, $gallery_image_id );
    if ($tags_json) { $tags = from_json( $tags_json ); }

    if ($tags) {
        
        foreach my $t (reverse @{ $tags}) {
            if ($allow_delete) { $HTML .= "<a href=\"#\" tag=\"" . $t->{tag} . "\" tag_id=\"" . $t->{id} . "\" id=\"delete_tag\" $del_style>x</a>"; }
            $HTML .= "<span class=\"image_tag\"><a href=\"/tag/" . $t->{tag} . "\">" . $t->{tag} . "</a></span> ";
        }
    } else {
        $HTML .= "no tags yet";
    }

    $c->response->body($HTML);
}



__PACKAGE__->meta->make_immutable;

1;
