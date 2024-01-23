package WorldOfAnime::Model::Comments::ProfileComment;
use Moose;
use JSON;
use List::MoreUtils qw(uniq);

BEGIN { extends 'WorldOfAnime::Model::Comments::Comment' }


has 'user_id' => (
# This is whose profile the comment is on, not who made it (that is commenter_id)
    is => 'rw',
    isa => 'Int',
);

has 'parent_comment_id' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'replies' => (
# json string    
    is => 'rw',
    isa => 'Maybe[Str]',
);



sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    $self->empty;  # Make sure we always end with an empty id
    
    my $cid = "woa:profile_comment:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->type( $cached->type );
        $self->commenter_id( $cached->commenter_id );
        $self->comment( $cached->comment );
        $self->user_id( $cached->user_id );
        $self->parent_comment_id( $cached->parent_comment_id );
        $self->createdate( $cached->createdate );
        $self->replies(''); # Initialize with no replies

    } else {

        my $Comment  = $c->model("DB::UserComments")->find($id);

	   if (defined($Comment)) {
	        $self->id( $Comment->id );
            $self->type('1');
            $self->commenter_id( $Comment->comment_user_id );
            $self->comment( $c->model('Formatter')->clean_html($Comment->comment) );
            $self->user_id( $Comment->user_id );
            $self->parent_comment_id( $Comment->parent_comment_id );
            $self->createdate( $Comment->createdate );
            $self->replies(''); # Initialize with no replies
           
            $c->cache->set($cid, $self, 2592000);
        } else {

        }
    }
}


sub build_replies {
    my $self = shift;
    my ( $c ) = @_;
    
    $self->replies(''); # Empty out replies
    my $id = $self->id;
    
    my $cid = "woa:profile_comment_replies:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->replies( $cached );

    } else {

        my $Replies = $c->model('DB::UserComments')->search_literal("parent_comment_id = $id");

	if (defined($Replies)) {
            my $replies;

            while (my $r = $Replies->next) {
                my $id = $r->id;
		my $comment_user_id = $r->comment_user_id;
		my $comment = $r->comment;
                
                push (@{ $replies}, { 'id' => "$id", 'comment_user_id' => "$comment_user_id", 'comment' => "$comment" });
            }
            
            if ($replies) {
                my $json_text = to_json($replies);
                $self->replies( $json_text );
                $c->cache->set($cid, $json_text, 2592000);
            }            
           
        }
    }    
}


sub profile_ids {
    my $self = shift;
    my $c = shift;
    my $replies;
    my @profile_ids;
    
    if ($self->replies) { $replies = from_json( $self->replies ); }

    foreach my $r (@{ $replies}) {
	push (@profile_ids, $r->{comment_user_id});
    }

    return (uniq(@profile_ids));
}


sub raw_comment_html {
    my ( $self, $c) = @_;
    my $html;
    my $replies;
    
    if ($self->replies) { $replies = from_json( $self->replies ); }
    
    foreach my $r (@{ $replies}) {
	$html .= $r->{comment};
    }
    
    return $html;
}


sub empty {
    my $self = shift;

    $self->id(0);
    $self->type(0);
    $self->commenter_id(0);
    $self->comment('');
    $self->user_id(0);
    $self->parent_comment_id(0);
    $self->createdate();
    $self->replies(''); # Initialize with no replies
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    my $parent = $self->parent_comment_id;
    
    $c->cache->remove("woa:profile_comment:$id");
    $c->cache->remove("woa:profile_comment_replies:$parent");
}



1;