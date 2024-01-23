package WorldOfAnime::Controller::DAO_Messages;
use Moose;
use JSON;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }



sub GetMessagesFromUser :Local {
    my ( $c, $to_user_id, $from_user_id ) = @_;
    my $messages;

    my $PMs = $c->model("DB::PrivateMessages")->search({
	-and => [
	    user_id => $to_user_id,
	    from_user_id => $from_user_id,
            is_deleted => 0,
	],
    },{
      select    => [ 'id',
		     'user_id',
		     'from_user_id',
                     'subject',
		     'message',
                     'is_read',
		     'createdate' ],

      order_by  => 'createdate DESC',
    });
    
    if (defined($PMs)) {
        while (my $p = $PMs->next) {
            my $id         = $p->id;
            my $subject    = $p->subject;
            my $message    = substr($p->message, 0, 75) . "...";
            my $is_read    = $p->is_read;
            my $createdate = $p->createdate;
            
            push (@{ $messages}, { 'id' => "$id", 'subject' => "$subject", 'message' => "$message", 'is_read' => "$is_read", 'createdate' => "$createdate" });
        }
        
        if ($messages) {
            my $json_text = to_json($messages);
            return $json_text;
        }
    
    }
    
}



sub GetMessagesToUser :Local {
    my ( $c, $from_user_id, $to_user_id ) = @_;
    my $messages;

    my $PMs = $c->model("DB::PrivateMessages")->search({
	-and => [
	    user_id => $to_user_id,
	    from_user_id => $from_user_id,
	],
    },{
      select    => [ 'id',
		     'user_id',
		     'from_user_id',
                     'subject',
		     'message',
                     'is_read',
		     'createdate' ],

      order_by  => 'createdate DESC',
    });
    
    if (defined($PMs)) {
        while (my $p = $PMs->next) {
            my $id         = $p->id;
            my $subject    = $p->subject;
            my $message    = substr($p->message, 0, 75) . "...";
            my $is_read    = $p->is_read;
            my $createdate = $p->createdate;
            
            push (@{ $messages}, { 'id' => "$id", 'subject' => "$subject", 'message' => "$message", 'is_read' => "$is_read", 'createdate' => "$createdate" });
        }
        
        if ($messages) {
            my $json_text = to_json($messages);
            return $json_text;
        }
    
    }
    
}

__PACKAGE__->meta->make_immutable;

1;
