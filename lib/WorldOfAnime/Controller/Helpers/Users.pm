package WorldOfAnime::Controller::Helpers::Users;
use JSON;

use parent 'Catalyst::Controller';

sub GetUserID :Local {
    my ( $c ) = @_;
    
    if ( $c->user_exists() ) {
        return $c->user->get('id')
    }
    
    return "";
}

# Use this method to pass a json structure, and return a json structure that has profile images
# included in the structure
sub WeaveProfileImages :Local {
	my ( $c, $json ) = @_;
	my $output;

	my $entries = from_json( $json );

	# Cache thumb profile image
	# Remove cache whenever person changes it

	foreach my $e (@{ $entries}) {

		if (exists($e->{id})) {
			($e->{profile_image_id}, $e->{thumb_url}) = split(/,/, GetUserProfileImage( $c, $e->{id}, "thumb" ));
		}

		push (@{ $output}, $e);
	}

	return to_json($output);
}


sub GetUserProfileImage :Local {
	my ( $c, $user_id, $type ) = @_;
	my $image_url;

    # Redis cache client and key
    my $redis = $c->model('Redis');
    my $key   = "woa/members/profile_image/$type/$user_id";

    $image_url = $redis->client->get($key);

    if ($image_url) { 
        return $image_url;
        $c->detach();
    }

    # If we get here, the image was not in cache
    # Get it, then cache it

	my $p = $c->model('Users::UserProfile');
   	$p->get_profile_image( $c, $user_id );
   	my $profile_image_id = $p->profile_image_id;
        
   	my $i = $c->model('Images::Image');
   	$i->build($c, $profile_image_id);
   	my $profile_image_url;

    if ($type eq "thumb") {
		$profile_image_url = $i->thumb_url;
	}

    if ($type eq "small") {
		$profile_image_url = $i->small_url;
	}

    if ($type eq "full") {
		$profile_image_url = $i->full_url;
	}

	my $value = $p->profile_image_id . "," . $profile_image_url;

	# Set cache for 30 days
    $redis->client->setex($key, (30 * 24 * 60 * 60), $value);

	return $value;
}

1;