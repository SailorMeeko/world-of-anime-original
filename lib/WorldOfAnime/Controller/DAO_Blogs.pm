package WorldOfAnime::Controller::DAO_Blogs;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


# Fetch a blog by id (uncached)
sub GetBlogByID :Local {
    my ( $c, $id ) = @_;
    my $Blog;

    unless ($Blog) {

        $Blog = $c->model('DB::Blogs')->find({
            id => $id,
        });

    }
    
    return $Blog;
}



# Fetch a cacheable blog by id (cache by hashref)
sub GetCacheableBlogByID :Local {
    my ( $c, $id ) = @_;
    my %blog;
    my $blog_ref;
    
    my $cid = "worldofanime:blog:$id";
    $blog_ref = $c->cache->get($cid);
    
    unless ($blog_ref) {
        my $Blog = $c->model('DB::Blogs')->find({
            id      => $id,
        });
	
	if (defined($Blog)) {

	    $blog{'id'}           = $Blog->id;	    
	    $blog{'user_id'}      = $Blog->user_id;
            $blog{'username'}     = $Blog->blog_user->username;
	    $blog{'subject'}      = $Blog->subject;
	    $blog{'post'}         = $Blog->post;
            $blog{'modifydate'}   = $Blog->modifydate;
            $blog{'createdate'}   = $Blog->createdate;
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%blog, 2592000);
	
	
    } else {
	%blog = %$blog_ref;
    }    
    
    return \%blog;
}


# Perform blog cache cleanup
sub BlogCleanup :Local {
    my ( $c, $id ) = @_;

    $c->cache->remove("worldofanime:blog:$id");
    $c->cache->remove("worldofanime:latest_blog_entries");
}


__PACKAGE__->meta->make_immutable;

1;
