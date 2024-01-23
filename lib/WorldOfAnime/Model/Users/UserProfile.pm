package WorldOfAnime::Model::Users::UserProfile;
use Moose;
use Moose::Util::TypeConstraints;
use JSON;
use Date::Calc qw( check_date );
use DateTime::Format::DateManip;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'name' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'username' => (
  is => 'rw',
  isa => 'Str',
);

has 'gender' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);


has 'birthday' => (
  is => 'rw',
#  isa => 'DateTime',
);

has 'is_valid_birthday' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

#subtype 'BDay'
#  => as 'DateTime';
#  
  
#has 'birthday' => (
#  is => 'rw',
#  isa => 'BDay',
#  coerce => 1,
#);


#coerce 'BDay'
#  => from 'Str'
#  => via {
#    DateTime::Format::DateManip->parse_datetime( $_ );
#};

has 'profile_image_id' => (
    is => 'rw',
    isa => 'Str',
);

has 'show_age' => (
    is => 'rw',
    isa => 'Int',
);

has 'show_gallery_to_all' => (
    is => 'rw',
    isa => 'Int',
);

has 'show_actions' => (
    is => 'rw',
    isa => 'Int',
);

has 'show_visible' => (
    is => 'rw',
    isa => 'Int',
);

has 'about_me' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'timezone' => (
  is => 'rw',
  isa => 'Str',
);

has 'twitter' => (
  is => 'rw',
  isa => 'Str',
);

has 'signature' => (
  is => 'rw',
);

has 'modifydate' => (
  is => 'rw',
  isa => 'DateTime',
);

has 'createdate' => (
  is => 'rw',
  isa => 'DateTime',
);

has 'error_message' => (
  is => 'rw',
  isa => 'Str',
);


has 'profile_image_name' => (
    is => 'rw',
    isa => 'Str',
);

has 'profile_image_dir' => (
    is => 'rw',
    isa => 'Str',
);

has 'profile_image_height' => (
    is => 'rw',
#    isa => 'Maybe[Int]',
);

has 'profile_image_width' => (
    is => 'rw',
#    isa => 'Maybe[Int]',
);



sub build {
    my $self = shift;
    my ( $c, $user_id ) = @_;

    my $cid = "woa:user_profile:$user_id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {
        
        $self->user_id( $cached->user_id );
	    $self->username( $cached->username );
        $self->name( $cached->name );
        $self->gender( $cached->gender );
        $self->timezone( $cached->timezone );
        $self->signature( $cached->signature );
        $self->show_age( $cached->show_age );
        $self->show_actions( $cached->show_actions );
        $self->show_visible( $cached->show_visible );
        $self->about_me( $cached->about_me );
        $self->birthday( $cached->birthday );
        $self->profile_image_id( $cached->profile_image_id );

    } else {

        my $Profile  = $c->model('DB::UserProfile')->find({ user_id => $user_id });

	if (defined($Profile)) {
            
            $self->user_id( $user_id );
	        $self->username( $Profile->user_id->username );
	        $self->name( $Profile->name );
            $self->gender( $Profile->gender );
            $self->timezone( $Profile->timezone );
            $self->signature( $Profile->signature );
            $self->show_age( $Profile->show_age );
            $self->show_actions( $Profile->show_actions );
            $self->show_visible( $Profile->show_visible );
            $self->about_me( $Profile->about_me );
            $self->birthday( $Profile->birthday );
            $self->profile_image_id( $Profile->profile_image_id );
            
            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub update {
    my $self = shift;
    my ( $c ) = @_;
    
    my $show_gallery_to_all = 0;
    
    my $show_age     = ($c->req->params->{'show_age'}) ? 1 : 0;
    my $show_actions = ($c->req->params->{'show_actions'}) ? 1 : 0;
    my $show_visible = ($c->req->params->{'show_visible'}) ? 1 : 0;
    
    $self->name( $c->req->params->{'profile_name'} );
    $self->gender( $c->req->params->{'gender'} );
    $self->timezone( $c->req->params->{'timezone'} );
    $self->signature( $c->req->params->{'signature'} );
    $self->show_age( $show_age );
    $self->show_actions( $show_actions );
    $self->show_visible( $show_visible );
    $self->about_me( $c->req->params->{'about_me'} );
    
}


sub save {
    my $self = shift;
    my ( $c ) = @_;
    
    $c->model("DB::UserProfile")->update_or_create({
	    user_id   => $self->user_id,
	    name      => $self->name,
        gender    => $self->gender,
	    timezone  => $self->timezone,
	    signature => $self->signature,
    	show_age  => $self->show_age,
	    show_actions => $self->show_actions,
	    show_visible => $self->show_visible,
	    about_me     => $self->about_me,
	    profile_image_id => $self->profile_image_id,
  	    birthday => $self->birthday,
	    },{ key => 'user_id' });
    
    $self->clear( $c );
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;

    my $user_id = $self->user_id;
    
    # Their main woa user profile    
    $c->cache->remove("woa:user_profile:$user_id");
    
    # Their profile image
    $c->cache->remove("woa:user_profile_image:$user_id");

    # Their online status (old version)
    # If show_visible is 0, try to remove their "is online" status from memcached
    unless ($self->show_visible) {
	$c->cache->remove("worldofanime:online:$user_id");
    }
    
}


sub get_profile_image {
    my $self = shift;
    my ( $c, $user_id ) = @_;
    
    # Clear to make sure we are starting fresh
    $self->profile_image_id("");
    $self->profile_image_name("");
    $self->profile_image_dir("");
    $self->profile_image_height("");
    $self->profile_image_width("");
    
    my $cid = "woa:user_profile_image:$user_id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

    $self->profile_image_id( $cached->profile_image_id );
	$self->profile_image_name( $cached->profile_image_name );
	$self->profile_image_dir( $cached->profile_image_dir );
	$self->profile_image_height( $cached->profile_image_height );
	$self->profile_image_width( $cached->profile_image_width );
	
    } else {
	
	my $Profile  = $c->model('DB::UserProfile')->find({ user_id => $user_id });
	
	if (defined($Profile)) {
	    
	    my $ProfileImageId = $Profile->profile_image_id;
	    
	    # Check to make sure their profile image_id is good
	    
	    my $ProfileImage = $c->model('DB::Images')->find( $Profile->profile_image_id );
	    if (!defined($ProfileImage)) {
		$ProfileImageId = 14;  # Hard coded default image - change this!
	    }
	    
	    my $i = $c->model('Images::Image');
	    $i->build($c, $ProfileImageId);	    
	    
	    $self->profile_image_id( $ProfileImageId );
	    $self->profile_image_name( $i->filename );
	    $self->profile_image_dir( $i->filedir );
	    $self->profile_image_height( $i->height );
	    $self->profile_image_width( $i->width );
	    
	    $c->cache->set($cid, $self, 2592000);
	}
	
    }
    
}


sub validate_birthday {
    my $self = shift;
    my ( $c ) = @_;
    
    # Assume we have a valid birthday
    
    $self->is_valid_birthday(1);
    $self->error_message();

    
    my $birthday = $c->req->params->{'birthday'};
    $birthday =~ s/\//\-/g; # Substitue / with -, just 'cause I'm so darn nice
    
    unless ( $birthday ) { $self->birthday(undef); }

    my @date = split(/\-/, $birthday);

    if ($birthday) {

        if (!($birthday =~ /(\d\d\d\d)\-(\d\d)\-(\d\d)/)) {
            $self->error_message("I'm sorry, $birthday is not in the valid format of YYYY-MM-DD");
            $self->is_valid_birthday(0);
        } elsif (!(check_date(@date) )) {
            $self->error_message("I'm sorry, $birthday is not a valid date.");
            $self->is_valid_birthday(0);
        } else {
            my $bday = DateTime::Format::DateManip->parse_datetime( $birthday );
            $self->birthday($bday);
        }
    }

}


1;