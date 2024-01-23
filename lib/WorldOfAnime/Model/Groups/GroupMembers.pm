package WorldOfAnime::Model::Groups::GroupMembers;
use Moose;
use JSON;

BEGIN { extends 'Catalyst::Model' }

has 'group_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'members' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'member_count' => (
    is => 'rw',
    isa => 'Int',
);


sub build {
    my $self = shift;
    my ( $c, $group_id ) = @_;

    my $cid = "woa:group_members:$group_id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->group_id( $cached->group_id );
        $self->members( $cached->members );
        $self->member_count( $cached->member_count );

    } else {

        my $Members  = $c->model('DB::GroupUsers')->search({
            -AND => [
                group_id => $group_id,
                user_id => { '!=', undef },
                ]});

	if (defined($Members)) {
            my %seen;
            my $count;
            my $members;
            
	    $self->group_id( $group_id );
            while (my $m = $Members->next) {
                my $member_id = $m->user_id->id;
                my $member_name = $m->user_id->username;
                my $member_email = $m->user_id->email;
                my $join_date = $m->createdate;
	    
                next if ($seen{$member_id});
                
                push (@{ $members} , { 'id' => "$member_id", 'name' => "$member_name", 'email' => "$member_email", 'join_date' => "$join_date" });
                $seen{$member_id} = 1;
                $count++;
            }            
            
            if ($members) {
                $self->members( to_json($members) );
                $self->member_count( $count );
            }
            
            $c->cache->set($cid, $self, 2592000);
        }
    }
}
    
1;