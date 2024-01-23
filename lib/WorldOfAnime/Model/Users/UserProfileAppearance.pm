package WorldOfAnime::Model::Users::UserProfileAppearance;
use Moose;
use Moose::Util::TypeConstraints;
use JSON;
use Date::Calc qw( check_date );

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'background_image_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'scroll_background' => (
    is => 'rw',
    isa => 'Int',
);

has 'repeat_x' => (
    is => 'rw',
    isa => 'Int',
);

has 'repeat_y' => (
    is => 'rw',
    isa => 'Int',
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



sub build {
    my $self = shift;
    my ( $c, $user_id ) = @_;

    my $cid = "woa:user_profile_appearance:$user_id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {
	
	$self->user_id( $cached->user_id );
	$self->background_image_id( $cached->background_image_id );
	$self->scroll_background( $cached->scroll_background );
	$self->repeat_x( $cached->repeat_x );
	$self->repeat_y( $cached->repeat_y );	

    } else {

        my $Profile  = $c->model('DB::UserProfile')->find({ user_id => $user_id });

	if (defined($Profile)) {
            
            $self->user_id( $user_id );
	    $self->background_image_id( $Profile->background_profile_image_id );
	    $self->scroll_background( $Profile->scroll_background );
	    $self->repeat_x( $Profile->repeat_x );
	    $self->repeat_y( $Profile->repeat_y );	    
            
            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub update {
    my $self = shift;
    my ( $c ) = @_;
    
    my $scroll_background = ($c->req->params->{'scroll_background'}) ? 1 : 0;
    my $repeat_x          = ($c->req->params->{'repeat_x'}) ? 1 : 0;
    my $repeat_y          = ($c->req->params->{'repeat_y'}) ? 1 : 0;
 
    $self->scroll_background( $scroll_background );
    $self->repeat_x( $repeat_x );
    $self->repeat_y( $repeat_y );
}


sub save {
    my $self = shift;
    my ( $c ) = @_;
    
    $c->model("DB::UserProfile")->update_or_create({
	    user_id   => $self->user_id,
	    background_profile_image_id => $self->background_image_id,
	    scroll_background => $self->scroll_background,
	    repeat_x => $self->repeat_x,
	    repeat_y => $self->repeat_y,
	    },{ key => 'user_id' });
    
    $self->clear( $c );
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;

    my $user_id = $self->user_id;
    
    # Their main woa user profile    
    $c->cache->remove("woa:user_profile_appearance:$user_id");
    $c->cache->remove("woa:css:user:$user_id");
}


1;