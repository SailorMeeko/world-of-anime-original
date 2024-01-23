package WorldOfAnime::Model::Messages::UserMessages;
use Moose;
use JSON;
use namespace::autoclean;

extends 'Catalyst::Model';


has 'user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'num_messages' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'all_users_received' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'all_users_sent' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'messages_from_users' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'messages_sent' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);


sub build {
    my $self = shift;
    my ( $c, $user_id ) = @_;

    my $cid = "woa:user_messages:$user_id";
    my $cached = $c->cache->get($cid);
    
    $self->all_users_received("");
    $self->all_users_sent("");
    $self->messages_from_users("");
    $self->messages_sent("");
    
    if (defined($cached)) {

        $self->user_id( $cached->user_id );
        $self->num_messages( $cached->num_messages );
        $self->all_users_received( $cached->all_users_received );
        $self->all_users_sent( $cached->all_users_sent );
        $self->messages_from_users( $cached->messages_from_users );
        $self->messages_sent( $cached->messages_sent );

    } else {

        $self->user_id( $user_id );

        # Who has sent them private messages?
        
        my $PMs = $c->model("DB::PrivateMessages")->search({
            -AND => [
                user_id => $user_id,
                is_deleted => 0,
            ],
            },{
            '+select' => [
		     'from_user_id',
                     ],
            '+as'     => [
		     'from_user_id',
                     ],
            group_by  => 'from_user_id',
        });

	if (defined($PMs)) {
            my $received_from;
            
            while (my $p = $PMs->next) {

                my $from_user_id = $p->from_user_id;
                my $p = $c->model('Users::UserProfile');
                $p->build( $c, $from_user_id );
                
                push (@{ $received_from}, { 'user_id' => "$from_user_id", 'username' => $p->username });
            }
            
            if ($received_from) {
                my $json_text = to_json($received_from);
                $self->all_users_received( $json_text );
                $c->cache->set($cid, $json_text, 2592000);
            }      
        }
        
        
        # Who have they sent a private message to?
        
        my $PMsTo = $c->model("DB::PrivateMessages")->search({
            -AND => [
                from_user_id => $user_id,
            ],
            },{
            '+select' => [
		     'user_id',
                     ],
            '+as'     => [
		     'user_id',
                     ],
            group_by  => 'user_id',
        });

	if (defined($PMsTo)) {
            my $sent_to;
            
            while (my $p = $PMsTo->next) {

                my $user_id = $p->user_id;
                my $p = $c->model('Users::UserProfile');
                $p->build( $c, $user_id );
                
                push (@{ $sent_to}, { 'user_id' => "$user_id", 'username' => $p->username });
            }
            
            if ($sent_to) {
                my $json_text = to_json($sent_to);
                $self->all_users_sent( $json_text );
                $c->cache->set($cid, $json_text, 2592000);
            }      
           
        }
        
        $c->cache->set($cid, $self, 2592000);        
    }
}


sub populate_all {
    my $self = shift;
    my ( $c ) = @_;
    
    my $messages_from_users;
    
    my $user_id = $self->user_id;
    my $all_users_json = $self->all_users_received;
    
    my $all_users;
    
    if ($all_users_json) { $all_users = from_json( $all_users_json ); }

    foreach my $u (@{ $all_users}) {  # All users that have sent a message
        my $id       = $u->{user_id};
        my $username = $u->{username};
        
        my $message_info;
        my $num_read;
        my $num_unread;
        my $latest;

        my $json_text = get_single_user_info( $c, $user_id, $id );
        
        if ($json_text) { $message_info = from_json( $json_text ); }
        
        foreach my $m (@{ $message_info}) {
            $num_read    = $m->{num_read};
            $num_unread  = $m->{num_unread};
            $latest      = $m->{latest};
        }
        
        push (@{ $messages_from_users}, { 'user_id' => "$id", 'username' => "$username", 'num_read' => "$num_read", 'num_unread' => "$num_unread", 'latest' => "$latest" });
    }
    
    if ($messages_from_users) {
        my $json_text = to_json($messages_from_users);
        $self->messages_from_users( $json_text );
    }         
}


sub populate_sent {
    my $self = shift;
    my ( $c ) = @_;
    
    my $messages_to_users;
    
    my $user_id = $self->user_id;
    my $all_users_sent_json = $self->all_users_sent;
    
    my $all_users;
    
    if ($all_users_sent_json) { $all_users = from_json( $all_users_sent_json ); }

    foreach my $u (@{ $all_users}) {  # All users that have been sent a message
        my $id       = $u->{user_id};
        my $username = $u->{username};
        
        my $message_info;
        my $num_total;
        my $latest;

        my $json_text = get_single_user_sent( $c, $user_id, $id );
        
        if ($json_text) { $message_info = from_json( $json_text ); }
        
        foreach my $m (@{ $message_info}) {
            $num_total  = $m->{num_total};
            $latest     = $m->{latest};
        }
        
        push (@{ $messages_to_users}, { 'user_id' => "$id", 'username' => "$username", 'num_total' => "$num_total", 'latest' => "$latest" });
    }
    
    if ($messages_to_users) {
        my $json_text = to_json($messages_to_users);
        $self->messages_sent( $json_text );
    }         
}


sub model_find_single_user_info {
    my $self = shift;
    my ( $c, $user_id, $id ) = @_;
    
    my $json_text = get_single_user_info( $c, $user_id, $id );
    return $json_text;
}


sub get_single_user_info {
    my ( $c, $user_id, $id ) = @_;

    # $user_id is the person who received the messages
    # $id is the sender of those messages
    
    my $cid = "woa:pm_count:$user_id:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {
        
        return $cached;
        
    } else {
        my $message_info;
        #my $num_total;
        my $num_read = 0;
        my $num_unread = 0;
        my $latest;
        
        my $PMs = $c->model('DB::PrivateMessages')->search({
            -and => [
                user_id => $user_id,
                from_user_id => $id,
                is_deleted => 0,
            ],
        },{
            order_by  => 'createdate ASC',
          });
        
        if (defined($PMs)) {
            while (my $p = $PMs->next) {
                if ($p->is_read) {
                    $num_read++;
                } else {
                    $num_unread++;
                }
                $latest = $p->createdate;
            }
            
            push (@{ $message_info}, { 'num_read' => "$num_read", 'num_unread' => "$num_unread", 'latest' => "$latest" });

            if ($message_info) {
                my $json_text = to_json($message_info);
                $c->cache->set($cid, $json_text, 2592000);
                return $json_text;
            }              
        }
    }
}


sub get_single_user_sent {
    my ( $c, $user_id, $id ) = @_;

    # $user_id is the person who sent the message
    # $id is the person receiving
    
    my $cid = "woa:pm_sent_count:$user_id:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {
        
        return $cached;
        
    } else {
        my $message_info;
        my $num_total;
        my $latest;
        
        my $PMsTo = $c->model('DB::PrivateMessages')->search({
            -and => [
                user_id => $id,
                from_user_id => $user_id,
            ],
        },{
            order_by  => 'createdate ASC',
          });
        
        if (defined($PMsTo)) {
            while (my $p = $PMsTo->next) {
                $num_total++;
                $latest = $p->createdate;
            }
            
            push (@{ $message_info}, { 'num_total' => "$num_total", 'latest' => "$latest" });

            if ($message_info) {
                my $json_text = to_json($message_info);
                $c->cache->set($cid, $json_text, 2592000);
                return $json_text;
            }              
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
