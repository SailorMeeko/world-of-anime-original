package WorldOfAnime::Model::Messages::Thread;
use Moose;
use JSON;
use namespace::autoclean;

extends 'Catalyst::Model';

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'messages' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);


sub build {
    my $self = shift;
    my ( $c, $id ) = @_;

    my $cid = "woa:pm_thread:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->messages( $cached->messages );

    } else {
        my $all_messages;
        
        $self->id( $id );
        # Start with initial PM
        my $PM = $c->model("DB::PrivateMessages")->find($id);

        if (defined($PM)) {
            
            my $message_id    = $PM->id;
            my $to_user_id    = $PM->user_id;
            my $to_username   = $PM->messages_to_users->username;
            my $from_user_id  = $PM->from_user_id;
            my $from_username = $PM->messages_from_users->username;
            my $subject       = $PM->subject;
            my $message       = $PM->message;
            my $createdate    = $PM->createdate;
            
            push (@{ $all_messages}, { 'message_id' =>  $message_id, 'to_user_id' => "$to_user_id", 'to_username' => "$to_username", 'from_user_id' => "$from_user_id", 'from_username' => "$from_username", 'subject' => "$subject", 'message' => "$message", 'createdate' => "$createdate" });
        }
            
        # Add all replies

        my $PMs = $c->model("DB::PrivateMessages")->search({ parent_pm => $id },{ order_by  => 'createdate ASC',});
        
        if (defined($PMs)) {
            while (my $PM = $PMs->next) {

                my $message_id    = $PM->id;
                my $to_user_id    = $PM->user_id;
                my $to_username   = $PM->messages_to_users->username;
                my $from_user_id  = $PM->from_user_id;
                my $from_username = $PM->messages_from_users->username;
                my $subject       = $PM->subject;
                my $message       = $PM->message;
                my $createdate    = $PM->createdate;
                
                push (@{ $all_messages}, { 'message_id' =>  $message_id, 'to_user_id' => "$to_user_id", 'to_username' => "$to_username", 'from_user_id' => "$from_user_id", 'from_username' => "$from_username", 'subject' => "$subject", 'message' => "$message", 'createdate' => "$createdate" });
            }
        }
        
    if ($all_messages) {
        my $json_text = to_json($all_messages);
        $self->messages( $json_text );
    }              
        
    $c->cache->set($cid, $self, 2592000);
    }
}




__PACKAGE__->meta->make_immutable;

1;
