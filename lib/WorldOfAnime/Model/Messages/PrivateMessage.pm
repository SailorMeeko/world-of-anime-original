package WorldOfAnime::Model::Messages::PrivateMessage;
use Moose;
use JSON;
use namespace::autoclean;

extends 'Catalyst::Model';

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'parent_pm' => (
    is => 'rw',
    isa => 'Int',
);

has 'subject' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'message' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'is_read' => (
    is => 'rw',
    isa => 'Int',
);

has 'is_deleted' => (
    is => 'rw',
    isa => 'Int',
);

has 'user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'from_user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'from_username' => (
    is => 'rw',
    isa => 'Str',
);

has 'to_username' => (
    is => 'rw',
    isa => 'Str',
);

has 'createdate' => (
    is => 'rw',
    isa => 'DateTime',
);


sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:pm:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->parent_pm( $cached->parent_pm );
        $self->subject( $cached->subject );
        $self->message( $cached->message );
        $self->is_read( $cached->is_read );
        $self->is_deleted( $cached->is_deleted );
        $self->user_id( $cached->user_id );
        $self->from_user_id( $cached->from_user_id );
        $self->from_username( $cached->from_username );
        $self->to_username( $cached->to_username );
        $self->createdate( $cached->createdate );

    } else {
        
        my $PM = $c->model("DB::PrivateMessages")->find($id);
        
        if (defined($PM)) {
            
            $self->id($PM->id);
            $self->parent_pm( $PM->parent_pm);
            $self->subject($PM->subject);
            $self->message($PM->message);
            $self->is_read($PM->is_read);
            $self->is_deleted($PM->is_deleted);
            $self->user_id($PM->user_id);
            $self->from_user_id($PM->from_user_id);
            $self->from_username($PM->messages_from_users->username);
            $self->to_username($PM->messages_to_users->username);
            $self->createdate($PM->createdate);
            
            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub mark_read {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    
    my $PM = $c->model("DB::PrivateMessages")->find($id);
    $PM->update({ is_read => 1 });
    
    $self->clean( $c );
}


sub delete {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id = $self->id;
    my $user_id = $self->user_id;
    my $from_id = $self->from_user_id;    
    
    my $PM = $c->model("DB::PrivateMessages")->find($id);
    $PM->update({ is_deleted => 1 });
    
    $c->cache->remove("woa:pm:$id");
    $c->cache->remove("woa:pm_count:$user_id:$from_id");
    
    # Check to see if we have any left from this user
    # If we get to 0, we need to remove woa:user_messages:$user_id as well
    
    my $messages;
    my $total;
    
    my $pms = $c->model('Messages::UserMessages');
    $pms->build( $c, $user_id );
    my $messages_json = $pms->model_find_single_user_info( $c, $user_id, $from_id );
    
    if ($messages_json) { $messages = from_json( $messages_json ); }
    
    foreach my $m (@{ $messages}) {
        $total += $m->{num_read};
        $total += $m->{num_unread};
    }
    
    unless ($total) {
        $c->cache->remove("woa:user_messages:$user_id");
    }
}


sub clean {
    my $self = shift;
    my ( $c ) = @_;
    
    my $id      = $self->id;
    my $user_id = $self->user_id;
    my $from_id = $self->from_user_id;
    
    $c->cache->remove("woa:pm:$id");
    $c->cache->remove("woa:num_unread_pms:$user_id");
    $c->cache->remove("woa:pm_count:$user_id:$from_id");
}

__PACKAGE__->meta->make_immutable;

1;
