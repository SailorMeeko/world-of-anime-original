package WorldOfAnime::Model::Images::Image;
use Moose;
use File::Remove 'remove';
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

has 'is_s3' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'is_deleted' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);


# 0 = not checked yet
# 1 = appropriate
# 2 = explicitly marked as not appropriate

has 'is_appropriate' => (
    is => 'rw',
    isa => 'Maybe[Int]',
    default => 0,
);

has 'filedir' => (
    is => 'rw',
    isa => 'Str',
);

has 'filename' => (
    is => 'rw',
    isa => 'Str',
);

has 'filetype' => (
    is => 'rw',
    isa => 'Str',
);

has 'filesize' => (
    is => 'rw',
    isa => 'Int',
);

has 'height' => (
    is => 'rw',
    isa => 'Int',
);

has 'width' => (
    is => 'rw',
    isa => 'Int',
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

    my $cid = "woa:image:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->user_id( $cached->user_id );
        $self->is_s3( $cached->is_s3 );
        $self->is_deleted( $cached->is_deleted );
        $self->is_appropriate( $cached->is_appropriate );        
        $self->filedir( $cached->filedir );
        $self->filename( $cached->filename );
        $self->filetype( $cached->filetype );
        $self->filesize( $cached->filesize );
        $self->height( $cached->height );
        $self->width( $cached->width );
        $self->modifydate( $cached->modifydate );
        $self->createdate( $cached->createdate );
        
    } else {
        
        my $Image = $c->model('DB::Images')->find($id);
        
        if (defined($Image)) {
            
            $self->id( $Image->id );
            $self->user_id( $Image->user_id );
            $self->is_s3( $Image->is_s3 );
            $self->is_deleted( $Image->is_deleted );
            $self->is_appropriate( $Image->is_appropriate );
            $self->filedir( $Image->filedir );
            $self->filename( $Image->filename );
            $self->filetype( $Image->filetype );
            $self->filesize( $Image->filesize );
            $self->height( $Image->height );
            $self->width( $Image->width );
            $self->modifydate( $Image->modify_date );
            $self->createdate( $Image->create_date );
            
            $c->cache->set($cid, $self, 2592000);        
        }
    }
}


sub thumb_url {
    my $self = shift;
    my $url;
    
    my $filedir  = $self->filedir;
    my $filename = $self->filename;
    my $height   = $self->height;
    my $width    = $self->width;
    
    $filedir =~ s/\/u\/?/\/t80/;
    $filedir =~ s/\/news\/?/\/t80/;
    
    if ($self->is_s3) {
        $url = "http://$filedir/$filename";
        $url =~ s/%/%25/g;
    } else {
        $url = "/$filedir/$filename";
    }

    return $url;
}


sub small_url {
    my $self = shift;
    my $url;
    
    my $filedir  = $self->filedir;
    my $filename = $self->filename;
    my $height   = $self->height;
    my $width    = $self->width;
    
    $filedir =~ s/\/u\/?/\/t175/;
    $filedir =~ s/\/news\/?/\/t175/;
    
    if ($self->is_s3) {
        $url = "http://$filedir/$filename";
        $url =~ s/%/%25/g;
    } else {
        $url = "/$filedir/$filename";
    }
    
    return $url;
}


sub full_url {
    my $self = shift;
    my $url;
    
    my $filedir  = $self->filedir;
    my $filename = $self->filename;
    my $height   = $self->height;
    my $width    = $self->width;
    
    if ($self->is_s3) {
        $url = "http://$filedir/$filename";
        $url =~ s/%/%25/g;
    } else {
        $url = "/$filedir$filename";
    }
    
    return $url;
}


sub delete_image {
    my $self = shift;
    my ( $c ) = @_;
    
    if ($self->is_s3) {
        my $s3 = $c->model('S3');
        my $bucket = $s3->client->bucket( 'images.worldofanime.com' );
        
        my $filedir = $self->filedir;
        $filedir =~ s/images\.worldofanime\.com\///;

        $bucket->delete_key('u/' . $self->filename);
        $bucket->delete_key('t80/' . $self->filename);
        $bucket->delete_key('t175/' . $self->filename);
        
    } else {
        my $root_dir  = $c->config->{baseimagefiledir};

        $root_dir =~ s/static\/images\/$//;
        
        my $file_u   = $root_dir . $self->filedir . $self->filename;
        my $file_80  = $file_u;
        my $file_175 = $file_u;
        
        $file_80  =~ s/\/u/\/t80/;
        $file_175 =~ s/\/u/\/t175/;
        
        remove($file_u);
        remove($file_80);
        remove($file_175);
        
    }
    
    my $Image = $c->model('DB::Images')->find( $self->id );
    $Image->update({ is_deleted => 1 });
    $self->clear;
}



sub verify_image {
    my $self = shift;
    my ( $c ) = @_;
    
    my $Image = $c->model('DB::Images')->find( $self->id );
    $Image->update({ is_deleted => 1 });
    $self->clear;
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
  
    $c->cache->remove("woa:image:$id");
}



__PACKAGE__->meta->make_immutable;

1;
