package WorldOfAnime::Model::Galleries::UserGalleries;
use Moose;
use JSON;
use namespace::autoclean;

extends 'Catalyst::Model';

has 'user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'galleries' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);


sub build {
    my $self = shift;
    my ( $c, $user_id ) = @_;

    my $cid = "woa:user_galleries:$user_id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->user_id( $cached->user_id );
        $self->galleries( $cached->galleries );

    } else {

        $self->user_id( $user_id );
        
        my $Galleries = $c->model('DB::Galleries')->search({ user_id => $user_id });

        unless ($Galleries->first) {
            # This person has no galleries
            # Create a Default Gallery and try again
        
            my $Gallery = $c->model("DB::Galleries")->create({
                user_id      => $user_id,
                gallery_name => 'Default Gallery',
                description  => 'My Default Image Gallery',
                num_images   => 0,
                inappropriate => 0,
                show_all => 1,
                modifydate   => undef,
                createdate   => undef,
            });
        }
        
        $Galleries = $c->model('DB::Galleries')->search({ user_id => $user_id },{
	  order_by  => 'createdate ASC',
	  });
        
	if (defined($Galleries)) {
            my $galleries;
            
            while (my $g = $Galleries->next) {
                my $id = $g->id;
                
                push (@{ $galleries}, { 'id' => "$id" });
            }
            
            if ($galleries) {
                my $json_text = to_json($galleries);
                $self->galleries( $json_text );
            }               

            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;
    
    my $user_id = $self->user_id;

    $c->cache->remove("woa:user_galleries:$user_id");
}


__PACKAGE__->meta->make_immutable;

1;
