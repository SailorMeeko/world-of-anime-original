package WorldOfAnime::Model::Galleries::Gallery;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

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

has 'description' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'num_images' => (
    is => 'rw',
    isa => 'Int',
);

has 'inappropriate' => (
    is => 'rw',
    isa => 'Int',
);

has 'show_all' => (
    is => 'rw',
    isa => 'Int',
);

has 'latest_image' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'modifydate' => (
    is => 'rw',
    isa => 'Maybe[DateTime]',
);

has 'createdate' => (
    is => 'rw',
    isa => 'Maybe[DateTime]',
);


sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:gallery:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->user_id( $cached->user_id );
        $self->name( $cached->name );
        $self->description( $cached->description );
        $self->num_images( $cached->num_images );
        $self->inappropriate( $cached->inappropriate );
        $self->show_all( $cached->show_all );

    } else {
        
        my $Gallery = $c->model('DB::Galleries')->find($id);
        
        if (defined($Gallery)) {
            
            $self->id( $Gallery->id );
            $self->user_id( $Gallery->user_id );
            $self->name( $Gallery->gallery_name );
            $self->description( $Gallery->description );
            $self->num_images( $Gallery->num_images );
            $self->inappropriate( $Gallery->inappropriate );
            $self->show_all( $Gallery->show_all );            

            $c->cache->set($cid, $self, 2592000);        
        }
    }
    
    $self->get_latest_image( $c );
}

sub add_new {
    my $self = shift;
    my ( $c, $user_id ) = @_;
    
    $c->model('DB::Galleries')->create({
	user_id => $user_id,
	gallery_name => $c->req->params->{'gallery_name'},
	description => $c->req->params->{'description'},
	show_all => $c->req->params->{'show_all'},
	modifydate   => undef,
        createdate   => undef,
    });
    
}


sub get_latest_image {
    my $self = shift;
    my ( $c ) = @_;

    my $id = $self->id;
    
    $self->latest_image(0); # Start empty
    
    my $cid = "woa:gallery:latest_image:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->latest_image( $cached->latest_image );
        
    } else {

        my $GalleryImage =  $c->model("DB::GalleryImages")->search( {
            -and => [
                gallery_id => $id,
                active => 1,
            ],
        },{
	  rows      => 1,
	  order_by  => 'createdate DESC',
	  });
        
        if (defined($GalleryImage)) {

            my $i = $GalleryImage->first;
            
            if (defined($i)) {
                $self->latest_image( $i->image_id );
            }
        }
        
        $c->cache->set($cid, $self, 2592000);                                    
    }
}


sub update {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    
    my $Gallery = $c->model('DB::Galleries')->find($id);

    $Gallery->update({
	gallery_name => $c->req->params->{gallery_name},
	description  => $c->req->params->{description},
	show_all     => $c->req->params->{show_all},
    });

    $self->clear( $c );    
}


sub update_image_count {
    my $self = shift;
    my ( $c, $new_count ) = @_;
    
    my $id = $self->id;
    
    my $Gallery = $c->model('DB::Galleries')->find($id);

    $Gallery->update({
	num_images => $new_count,
    });

    $self->clear( $c );        
}
    

sub clear {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;

    $c->cache->remove("woa:gallery:$id");
}


__PACKAGE__->meta->make_immutable;

1;
