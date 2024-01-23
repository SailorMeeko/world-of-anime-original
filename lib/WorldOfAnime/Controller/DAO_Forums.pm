package WorldOfAnime::Controller::DAO_Forums;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

WorldOfAnime::Controller::DAO_Forums - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut


# Fetch Number of Posts for a user
sub FetchNumPosts :Local {
    my ( $c, $id ) = @_;
    my $num_posts;
    
    my $cid = "worldofanime:num_forum_posts:$id";
    $num_posts = $c->cache->get($cid);
    
    unless ($num_posts) {
    
        my $Posts = $c->model('DB::ThreadPosts')->search({
            user_id => $id,
        });
    
        $num_posts = $Posts->count;
        
        # Set memcached object for 30 days
	$c->cache->set($cid, $num_posts, 2592000);
    }
    
    return $num_posts;
}


sub IsValidThread :Local {
    my ($c, $thread_id ) = @_;
    my $is_valid;
    
    my $cid = "woa:is_thread_valid:$thread_id";
    $is_valid = $c->cache->get($cid);
    
    unless (defined($is_valid)) {
	my $Thread = $c->model('DB::ForumThreads')->find( { id => $thread_id });
	
	if (defined($Thread)) {
	    $is_valid = 1;
	} else {
	    $is_valid = 0;
	}
	
	# Set memcached object for 30 days
	# Only if this is a valid thread
	# This is to prevent us from caching a thread id as being invalid, that later does become valid with a new thread
	
	if ($is_valid == 1) {
	    $c->cache->set($cid, $is_valid, 2592000);
	}
    }
    
    return $is_valid;
}


# Fetch first post of a thread (for SEO purposes - make meta description)
sub FetchFirstPostByThread :Local {
    my ( $c, $thread_id ) = @_;
    my $post;

    my $cid = "worldofanime:first_post_by_thread:$thread_id";
    $post = $c->cache->get($cid);
    
    unless ($post) {
	# We want the first post
	
	my $ThreadPost = $c->model('DB::ThreadPosts')->search({
	    thread_id => $thread_id,
	},{
	   rows => 1,
	   order_by => 'create_date ASC',
	});

	if ($ThreadPost) {
	    my $IndPost = $ThreadPost->next;
	    $post = $IndPost->post;
	    $post =~ s/\"//g;
	    $post =~ s/\n/ /g;
	    $post = substr($post,0,160);
	    $post =~ s/ (\S+)$//;

	    # Set memcached object for 30 days
	    $c->cache->set($cid, $post, 2592000);
	}
	
    }
    
    return $post;
}


# Fetch first thread of a forum (return as hash)
sub FetchFirstThreadByForum :Local {
    my ( $c, $forum_id ) = @_;
    my %thread;
    my $thread_ref;
    
    my $cid = "worldofanime:first_thread_by_forum:$forum_id";
    $thread_ref = $c->cache->get($cid);
    
    unless ($thread_ref) {
	my $Threads = $c->model('DB::ForumThreads')->search( {
	    forum_id => $forum_id,
	}, {
	    rows      => 1,
	    order_by  => 'last_post DESC',
	});
	
	if (defined($Threads)) {
	    my $FirstThread = $Threads->next;
	    
	    $thread{'subject'}   = $FirstThread->subject;
	    $thread{'id'}        = $FirstThread->id;
	    $thread{'last_post'} = $FirstThread->last_post;
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%thread, 2592000);
	
	
    } else {
	%thread = %$thread_ref;
    }
    
    return \%thread;
}


sub FetchPostByID :Local {
    my ( $c, $id ) = @_;
    my $Post;
    
    $Post = $c->model('DB::ThreadPosts')->find({
	id => $id,
    });
	
    return $Post;
}


sub FetchThreadPosts :Local {
    my ( $c, $id ) = @_;
    my $Posts;
    
    $Posts = $c->model('DB::ThreadPosts')->search({
	thread_id => $id,
    },{
	order_by => 'create_date ASC',
    });
    
    return $Posts;
}


sub FetchThreadsByForum :Local {
    my ( $c, $forum_id ) = @_;
    my $num_threads;
    
    my $cid = "worldofanime:num_forum_threads:$forum_id";
    $num_threads = $c->cache->get($cid);
    
    unless (defined($num_threads)) {
        
        my $Threads = $c->model('DB::ForumThreads')->search( { forum_id => $forum_id } );
	
	if (defined($Threads)) {
	    $num_threads = $Threads->count;
	    
	    # Set memcached object for 30 days
	    $c->cache->set($cid, $num_threads, 2592000);
	}
    }
    
    return $num_threads;
}


sub FetchForumPostForDisplay :Local {
    my ( $c, $id ) = @_;
    my $post_html;
    
    # If this is called for a newly printed post, we need the wrapper div
    # If this is called by ajax to replace an existing printed post, we don't need the wrapper div
    my $need_wrapper_div = 0;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $cid = "worldofanime:forum_post:$id";
    $post_html = $c->cache->get($cid);
    
    unless ($post_html) {
	my $post = $c->model('DB::ThreadPosts')->find({
	id => $id,
    });
	
    my $postid        = $post->id;
    my $userid        = $post->user_id->id;
    my $username      = $post->user_id->username;
    
    my $p = $c->model('Users::UserProfile');
    $p->get_profile_image( $c, $userid );
    my $profile_image_id = $p->profile_image_id;
    
    my $i = $c->model('Images::Image');
    $i->build($c, $profile_image_id);
    my $profile_image_url = $i->thumb_url;

    my $user_post     = $post->post;
    my $date          = $post->create_date;
    my $join_date     = $post->user_id->confirmdate;
    my $displayDate   = WorldOfAnime::Controller::Root::PrepareDate($date, 5, $tz);
    my $displayJoinDate = WorldOfAnime::Controller::Root::PrepareDate($join_date, 6, $tz);
    my $displaySubject  = $post->thread_id->subject;
    my $num_forum_posts = WorldOfAnime::Controller::DAO_Forums::FetchNumPosts($c, $post->user_id->id);
			
    unless (WorldOfAnime::Controller::DAO_Forums::IsFirstPost( $c, $id )) {
	$displaySubject = "Re: " . $displaySubject;
    }
	
    $user_post  = WorldOfAnime::Controller::DAO_Format::ParseBBCode($user_post);
			
    if ($need_wrapper_div) { $post_html .= "<div class=\"individual_post\" id=\"post_$postid\">\n"; }
    $post_html .= "<table width=\"100%\" cellpadding=\"2px\">\n";
    $post_html .= "<tr>\n";
    $post_html .= " <td class=\"forum_header\" colspan=\"2\">Posted by $username on $displayDate</td>\n";
    $post_html .= "</tr>\n";
    $post_html .= "<tr>\n";
    $post_html .= "	<td width=\"20%\" valign=\"top\"><div id=\"post_profile_image\">\n";

    $post_html .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a><p />";
    $post_html .= "<span class=\"forum_info\">Joined: " . $displayJoinDate . "</span><br />\n";
    $post_html .= "<span class=\"forum_info\">Posts: " . $num_forum_posts . "</span><br />\n";
    $post_html .= "</td>\n";
    $post_html .= "<td width=\"80%\" valign=\"top\" style=\"background: #FCFCF7; border-left: 1px solid #D1DEDD;\">";
			
    $post_html .= "<span class=\"forum_title\">" . $displaySubject . "</span>\n";
    $post_html .= "<span class=\"forum_post\">$user_post</span>";
			
    if ($post->user_id->user_profiles->signature) {
	my $signature  = WorldOfAnime::Controller::Root::ResizeComment($post->user_id->user_profiles->signature, 480);
	$post_html .= "<p style=\"border-top: 1px solid #D1DEDD; margin-top: 20px;\">$signature</p>\n";
    }
			
    $post_html .= "</td>\n";
			
    $post_html .= "<tr>\n";
    $post_html .= " <td class=\"forum_footer\" colspan=\"2\">";
    if ($viewer_id) {
	$post_html .= "<a href=\"#\" class=\"reply_thread\">Reply</a>\n";
	$post_html .= " . <a href=\"#\" class=\"reply_thread_quote\" id=\"$postid\" user=\"$username\">Reply with Quote</a>\n";
    }
    if ($viewer_id == $userid) {
	$post_html .= " . <a href=\"#\" class=\"edit_post\" id=\"$postid\">Edit</a>\n";
    }
			
    $post_html .= "</td>\n";
    $post_html .= "</tr>\n";

    $post_html .= "</table>\n";
    if ($need_wrapper_div) { $post_html .= "</div>\n"; }
    
    }
    
    return $post_html;
}



sub FetchForumPostContent :Local {
    my ( $c, $id ) = @_;
    my $post;

    my $cid = "worldofanime:forum_post_content:$id";
    $post = $c->cache->get($cid);
    
    unless ($post) {
	my $Post = $c->model('DB::ThreadPosts')->find({
	    id => $id,
	});
	
	if ($Post) {
	    $post     = $Post->post;
	}
	
    }
    
    return $post;
}



sub IsFirstPost :Local {
    my ( $c, $id ) = @_;
    my $is_first_post;
    my $post_id;
    my $first_post_id;
    
    my $Post = WorldOfAnime::Controller::DAO_Forums::FetchPostByID( $c, $id );
    return 0 unless ($Post);
    $post_id = $Post->id;

    my $ThreadPosts = WorldOfAnime::Controller::DAO_Forums::FetchThreadPosts( $c, $Post->thread_id->id);

    if ($ThreadPosts) {
	my $ThreadPost = $ThreadPosts->next;
	$first_post_id = $ThreadPost->id;
    }
    
    if ($post_id == $first_post_id) {
	return 1;
    } else {
        return 0;
    }
}


# Perform post-Post cleanup
sub PostCleanup :Local {
    my ( $c, $user_id, $thread_id, $forum_id ) = @_;
    
    $c->cache->remove("worldofanime:num_forum_posts:$user_id");
    $c->cache->remove("worldofanime:last_thread_poster:$thread_id");
    $c->cache->remove("worldofanime:first_thread_by_forum:$forum_id");
}


# Perform post-New Thread cleanup
sub PostNewThreadCleanup :Local {
    my ( $c, $forum_id ) = @_;
    
    $c->cache->remove("worldofanime:num_forum_threads:$forum_id");
}


sub FetchLastThreadPostUser :Local {
    my ($c, $id) = @_;
    my $user;
    
    return unless $id;
    
    #return $id;

    my $cid = "worldofanime:last_thread_poster:$id";
    $user = $c->cache->get($cid);
    
    unless ($user) {
        
        my $Post = $c->model('DB::ThreadPosts')->search({
            thread_id => $id,
        },
        {   rows => 1,
	    order_by => 'create_date DESC',});

	if ($Post) {
	    
	    #eval {
		my $IndPost = $Post->next;
		$user = $IndPost->user_id->username;
	    
		# Set memcached object for 30 days
		$c->cache->set($cid, $user, 2592000);
	    #}
	}
	
    }
    
    return $user;
}



=head1 AUTHOR

meeko,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
