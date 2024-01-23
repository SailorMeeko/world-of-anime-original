package WorldOfAnime::Controller::DAO_Groups;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }



# Fetch a cacheable user by id (cache by hashref)
sub GetCacheableGroupByID :Local {
    my ( $c, $id ) = @_;
    my %group;
    my $group_ref;
    
    my $cid = "worldofanime:group:$id";
    $group_ref = $c->cache->get($cid);
    
    unless ($group_ref) {
	my $Group = $c->model('DB::Groups')->find( {
	    id => $id,
	});
	
	if (defined($Group)) {

	    $group{'id'}          = $Group->id;	    
	    $group{'name'}        = $Group->name;
	    $group{'description'} = $Group->description;
	    $group{'profile_image_id'} = $Group->profile_image_id;
	    $group{'pretty_url'}  = $Group->pretty_url;
	    $group{'is_private'}  = $Group->is_private;
	    $group{'created_by'}  = $Group->created_by_user_id;
	    $group{'create_date'} = $Group->createdate;

	    # Try to get number of members
	    my $members_cid = "worldofanime:num_group_members:$id";
	    my $num_members = $c->cache->get($members_cid);
	    
	    unless ($num_members) {
		$num_members = 0; # Default
		
		my $m = $c->model('Groups::GroupMembers');
		$m->build( $c, $id );

		if ($m->members) {
		    $group{'num_members'} = $m->member_count;
		}

		# Set memcached object for 30 days
		$c->cache->set($members_cid, $num_members, 2592000);
		
	    } else {
		$group{'num_members'} = $num_members;
	    }
	
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%group, 2592000);
	
	
    } else {
	%group = %$group_ref;
    }    
    
    return \%group;
}



sub GetUserGroupStatus :Local {
    my ( $c, $UserID, $GroupID ) = @_;
    my $IsOwner = 0;
    my $IsAdmin = 0;
    my $IsMember = 0;
    my $IsJoinRequest = 0;

    my %status;
    my $status_ref;    
    
    my $g = WorldOfAnime::Controller::DAO_Groups::GetCacheableGroupByID( $c, $GroupID );
    my $created_by  = $g->{'created_by'};
    
    my $cid = "worldofanime:group_user_status:$GroupID:$UserID";
    $status_ref = $c->cache->get($cid);
    
    unless ($status_ref) {
	
        # Owner
        if ( ($UserID) && ($UserID == $created_by)) {
            $status{'IsOwner'} = 1;
            $status{'IsAdmin'} = 1;
            $status{'IsMember'} = 1;
        } else {
        # Admin
            my $Member = $c->model('DB::GroupUsers')->search({
                -and => [
		    group_id => $GroupID,
		    user_id  => $UserID,
		],
            });
        
            if ($Member->count) {
		my $m = $Member->next;
		
                if ($m->is_admin) {
                        $status{'IsAdmin'} = 1;
                        $status{'IsMember'} = 1;
                    } else {
                    # Or, member
                        $status{'IsMember'} = 1;
                    }
            } else {
                # Maybe they've asked to join?
                my $JoinRequest = $c->model('DB::GroupJoinRequests')->search({
		    -and => [
			group_id => $GroupID,
			user_id => $UserID,
		    ],
                });
            
                if ($JoinRequest->count) {
                    $status{'IsJoinRequest'} = 1;
                }
            
            }
	    
	    # Set memcached object for 30 days
	    $c->cache->set($cid, \%status, 2592000);	    
	}
	
    }  else {
	%status = %$status_ref;
    }
    
    $IsOwner = $status{'IsOwner'};
    $IsAdmin = $status{'IsAdmin'};
    $IsMember = $status{'IsMember'};
    $IsJoinRequest = $status{'IsJoinRequest'};
    
    return ($IsOwner, $IsAdmin, $IsMember, $IsJoinRequest);    
}



sub GetGroupMembers_JSON :Local :Args(1) {
    my ( $c, $id ) = @_;
    my $members;
    
    my $cid = "worldofanime:group_members_json:$id";
    $members = $c->cache->get($cid);

    unless ($members) {

	my $Members = $c->model('DB::GroupUsers')->search({
            group_id => $id,
	});

        while (my $m = $Members->next) {
	    my $member_id = $m->user_id->id;
	    my $member_name = $m->user_id->username;
	    my $member_email = $m->user_id->email;
	    
	    push (@{ $members} , { 'id' => "$member_id", 'name' => "$member_name", 'email' => "$member_email" });
	}

	
	# Set memcached object for 30 days
	$c->cache->set($cid, $members, 2592000);

    }
    
    if ($members) { return to_json($members); }
}



sub GetUserGroups :Local {
    my ( $c, $id ) = @_;
    my $UserGroups;
    
    $UserGroups = $c->model('DB::GroupUsers')->search({
        user_id => $id,
    },{
            order_by => 'is_admin, createdate DESC',
    });
    
    return $UserGroups;
}


sub GetUserGroups_JSON :Local {
    my ( $c, $id ) = @_;
    my $groups;

    my $cid = "woa:user_groups:$id";
    $groups = $c->cache->get($cid);

    unless ($groups) {

        my $UserGroups = $c->model('DB::GroupUsers')->search({
	    user_id => $id,
	},{
            order_by => 'is_admin, createdate DESC',
	});

        while (my $group = $UserGroups->next) {
	    my $group_id = $group->group_id->id;
	    
	    push (@{ $groups} , { 'id' => "$group_id" });
	}

	# Set memcached object for 30 days
	$c->cache->set($cid, $groups, 2592000);

    }
    
    if ($groups) { return to_json($groups); }    
}


sub FetchAdmins :Local {
    my ( $c, $group_id ) = @_;
    
    my $Admins = $c->model("DB::GroupUsers")->search({
	-and => [
	    group_id => $group_id,
	    is_admin => 1,
	],
    });
    
    return $Admins;
}


sub GetNumJoinRequests :Local {
    my ( $c, $group ) = @_;
    my $num_join_requests;
    
    my $cid = "worldofanime:num_group_join_requests:$group";
    $num_join_requests = $c->cache->get($cid);
    
    unless ($num_join_requests) {
    
        my $JoinRequests = $c->model("DB::GroupJoinRequests")->search({
            group_id => $group,
        });
        
        $num_join_requests = $JoinRequests->count;
        
        # Set memcached object for 30 days
	$c->cache->set($cid, $num_join_requests, 2592000);        
    }
    
    return $num_join_requests;
}


sub Search :Path('/groups/search') :Args(0) {
    my ( $self, $c ) = @_;
    my $results;
    my $count = 0;

    my $searchString = $c->req->params->{'searchString'};

    my $Groups = $c->model("DB::Groups")->search( {
	-and => [
	    -or => [
	        name => { 'like', "%$searchString%" },
	        description => { 'like', "%$searchString%" },
            ],
	    is_private => 0,
	]
    },
    {
	order_by => 'createdate DESC',
    });

        if ($Groups) {
            while (my $group = $Groups->next) {
                my $id    = $group->id;
	    
		my $g = WorldOfAnime::Controller::DAO_Groups::GetCacheableGroupByID( $c, $id );
		my $name        = $g->{'name'};
		my $members     = $g->{'num_members'};
		my $create_date = $g->{'create_date'};
		my $description = $c->model('Formatter')->clean_html($g->{'description'});
		my $prettyurl   = $g->{'pretty_url'};
		
		my $i = $c->model('Images::Image');
	        $i->build($c, $g->{'profile_image_id'});
		my $profile_image_url = $i->thumb_url;   	
		
		my $displayCreateDate = WorldOfAnime::Controller::Root::PrepareDate($create_date, 1);
		
		push (@{ $results}, { 'id' => "$id", 'name' => "$name", 'members' => "$members", 'create_date' => "$displayCreateDate", 'description' => "$description", 'profile_image_url' => $profile_image_url, 'prettyurl' => "$prettyurl" });
		$count++;
            }
        }

    WorldOfAnime::Controller::DAO_Searches::RecordSearch( $c, 2, $searchString, $count );
	
    if ($results) {
        my $json_text = to_json($results);
        $c->stash->{results} = $json_text;
        $c->forward('View::JSON');
    } else {
        $c->response->body('N');
    }
}


sub CleanupGroupJoinRequests :Local {
    my ( $c, $group ) = @_;
    
    $c->cache->remove("worldofanime:num_group_join_requests:$group");
}


sub CleanupGroupUserJoinRequests :Local {
    my ( $c, $user_id, $group_id ) = @_;
    
    $c->cache->remove("worldofanime:num_group_join_requests:$user_id");
    $c->cache->remove("worldofanime:num_group_join_requests:$group_id");
}


sub CleanGroup :Local {
    my ( $c, $group ) = @_;

    $c->cache->remove("worldofanime:group:$group");    
    $c->cache->remove("worldofanime:num_group_members:$group");    
}


sub CleanGroupMembers :Local {
    my ( $c, $group ) = @_;

    $c->cache->remove("worldofanime:group:$group");        
    $c->cache->remove("worldofanime:num_group_members:$group");
    $c->cache->remove("worldofanime:group_members_json:$group");
    $c->cache->remove("woa:group_members:$group");
}


sub CleanupGroupUserStatus :Local {
    my ( $c, $group, $user ) = @_;
    
    $c->cache->remove("worldofanime:group_user_status:$group:$user");
    $c->cache->remove("woa:user_groups:$user");
}


__PACKAGE__->meta->make_immutable;

1;
