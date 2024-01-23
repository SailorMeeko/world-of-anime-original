package WorldOfAnime::Model::Groups::Group;
use Moose;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'name' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'pretty_url' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'description' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'is_private' => (
    is => 'rw',
    isa => 'Int',
    default => '0',
);

has 'scroll_background' => (
    is => 'rw',
    isa => 'Int',
    default => '0',
);

has 'repeat_x' => (
    is => 'rw',
    isa => 'Int',
    default => '0',
);

has 'repeat_y' => (
    is => 'rw',
    isa => 'Int',
    default => '0',
);

has 'created_by' => (
    is => 'rw',
    isa => 'Str',
);

has 'created_by_user_id' => (
    is => 'rw',
    isa => 'Int',
    default => '0',
);

has 'profile_image_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'background_image_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
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
);

has 'profile_image_width' => (
    is => 'rw',
);


has 'createdate' => (
    is => 'rw',
    isa => 'DateTime',
);



sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:group:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->name( $cached->name );
        $self->pretty_url( $cached->pretty_url );
        $self->description( $cached->description );
        $self->is_private( $cached->is_private );
        $self->profile_image_id( $cached->profile_image_id );
        $self->background_image_id( $cached->background_image_id );
        $self->scroll_background( $cached->scroll_background );
        $self->repeat_x( $cached->repeat_x );
        $self->repeat_y( $cached->repeat_y );
        $self->createdate( $cached->createdate );
        $self->created_by_user_id( $cached->created_by_user_id );
        $self->created_by( $cached->created_by );

    } else {

        my $Group  = $c->model('DB::Groups')->find($id);

	if (defined($Group)) {
            
	    $self->id( $Group->id );
            $self->name( $Group->name );
            $self->pretty_url( $Group->pretty_url );
            $self->description( $Group->description );
            $self->is_private( $Group->is_private );
            $self->profile_image_id( $Group->profile_image_id );
            $self->background_image_id( $Group->background_image_id );
            $self->scroll_background( $Group->scroll_background );
            $self->repeat_x( $Group->repeat_x );
            $self->repeat_y( $Group->repeat_y );
            $self->createdate( $Group->createdate );
            $self->created_by_user_id( $Group->created_by_user_id );
            $self->created_by( $Group->group_creator->username );
            
            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub update {
    my $self = shift;
    my ( $c ) = @_;

    my $is_private        = ($c->req->params->{'is_private'}) ? 1 : 0;
    my $scroll_background = ($c->req->params->{'scroll_background'}) ? 1 : 0;
    my $repeat_x          = ($c->req->params->{'repeat_x'}) ? 1 : 0;
    my $repeat_y          = ($c->req->params->{'repeat_y'}) ? 1 : 0;
    
    my $name        = $c->req->params->{'name'};
    my $description = $c->req->params->{'description'};
    my $pretty_url  = $c->model('Formatter')->prettify( $name );    
    
    $self->is_private( $is_private );
    $self->scroll_background( $scroll_background );
    $self->repeat_x( $repeat_x );
    $self->repeat_y( $repeat_y );
    $self->name( $name );
    $self->description( $description );
    $self->pretty_url( $pretty_url );
}


sub save {
    my $self = shift;
    my ( $c ) = @_;

    my $Group  = $c->model('DB::Groups')->find( $self->id );
    
    $Group->update({
	    name        => $self->name,
	    description => $self->description,
            pretty_url  => $self->pretty_url,
            is_private  => $self->is_private,
	    profile_image_id => $self->profile_image_id,
            background_image_id => $self->background_image_id,
	    scroll_background => $self->scroll_background,
	    repeat_x => $self->repeat_x,
	    repeat_y => $self->repeat_y,            
    });
    
    $self->clear( $c );    
}


sub get_group_profile_image {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    
    # Clear to make sure we are starting fresh
    $self->profile_image_name("");
    $self->profile_image_dir("");
    $self->profile_image_height("");
    $self->profile_image_width("");
    
    my $cid = "woa:group_profile_image:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->profile_image_id( $cached->profile_image_id );
    } else {
	
	my $Group  = $c->model('DB::Groups')->find($id);
	
	if (defined($Group)) {
	    
            $self->profile_image_id( $Group->profile_image_id );
	    $c->cache->set($cid, $self, 2592000);
	}
	
    }
    
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    
    # Main group
    $c->cache->remove("woa:group:$id");
    
    # Group profile image
    $c->cache->remove("woa:group_profile_image:$id");
    
    # CSS styling (old memcached nameing)
    $c->cache->remove("worldofanime:css:group:$id");
}

1;