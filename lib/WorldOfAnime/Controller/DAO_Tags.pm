package WorldOfAnime::Controller::DAO_Tags;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }

sub GetTagID :Local {
    my ( $c, $tag ) = @_;
    my $tag_id;
    
    # Remove leading and trailing whitespace from tag, and lowercase it
    $tag =~ s/^ +//g;
    $tag =~ s/ +$//g;
    $tag = lc($tag);
    
    # Look it up in memcached
    
    my $cid = "worldofanime:tag_id:$tag";
    $cid = WorldOfAnime::Controller::Root::CleanKey( $cid );
    
    $tag_id = $c->cache->get($cid);
    
    unless ($tag_id) {
        
        # Add or update, and get key back
        
        my $Tag = $c->model('DB::Tags')->find({ tag => $tag } );
        
        if ($Tag) {
            # Tag exists
            
            $tag_id = $Tag->id;
        } else {
            # Tag does not exist, create it
            
            my $NewTag = $c->model('DB::Tags')->create({
                tag => $tag,
            });
            
            $tag_id = $NewTag->id;
        }
        
        # Set memcached object for 30 days
        $c->cache->set($cid, $tag_id, 2592000);        
    }
    
    return $tag_id;    
}


sub GetTagName :Local {
    my ( $c, $tag_id ) = @_;
    my $tag;

    # Look it up in memcached
    
    my $cid = "worldofanime:tag_name:$tag_id";
    $tag = $c->cache->get($cid);
    
    unless ($tag) {
        
        my $Tag = $c->model('DB::Tags')->find({ id => $tag_id } );
        
        if ($Tag) {
            # Tag exists
            
            $tag = $Tag->tag;
        }
        
        # Set memcached object for 30 days
        $c->cache->set($cid, $tag, 2592000);        
    }
    
    return $tag;    
}

__PACKAGE__->meta->make_immutable;

1;
