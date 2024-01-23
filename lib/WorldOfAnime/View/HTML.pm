package WorldOfAnime::View::HTML;

use strict;
use Time::Duration;
use DateTime::TimeZone;
use Scalar::Util;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        WorldOfAnime->path_to( 'root', 'src' ),
        WorldOfAnime->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    expose_methods => [qw/parse_bbcode clean_bbcode pick_ad prettify_date seconds_ago int group_css user_profile_css last_thread_post_user num_group_join_requests prettify_text create_pager
                       num_threads_by_forum fetch_last_thread get_last_action_date ra get_friend_requests get_unread_pms num_news_comments get_user_profile_image
		       show_star_rating display_comment gallery_info image_info pm_mark_read formatter clean_html/],
});

$Template::Directive::WHILE_MAX = 9999999;


sub last_thread_post_user {
    my ( $self, $c, $id ) = @_;
    my $user;
    
    $user = WorldOfAnime::Controller::DAO_Forums::FetchLastThreadPostUser($c, $id);
    
    return $user;
}


sub parse_bbcode {
    my ( $self, $c, $text ) = @_;
    
    my $new_text = WorldOfAnime::Controller::DAO_Format::ParseBBCode($text);
    
    return $new_text;
}


sub clean_bbcode {
    my ( $self, $c, $text ) = @_;
    
    my $new_text = WorldOfAnime::Controller::DAO_Format::CleanBBCode($text);
    
    return $new_text;
}


sub pick_ad {
    my ( $self, $c, $size_id, $all_approved ) = @_;
    my $Ads;
    
    my $ad_code;
    
    if ($all_approved) {
	$ad_code .= '<div class="approved_ads">';
    }
    
    $ad_code .= '<p class="break_code">';

    if ($all_approved) {

	$Ads = $c->model('DB::Ads')->search({
	    -and => [
		size_id => $size_id,
		active => 1,
		require_approval => 1,
	    ]
	},{
	    order_by => 'Rand()',
	});

    } else {

	$Ads = $c->model('DB::Ads')->search({
	    -and => [
		size_id => $size_id,
		active => 1,
		require_approval => 0,
	    ]
	},{
	    order_by => 'Rand()',
	});	
	
    }
    
    if ($Ads->count) {
        my $ad = $Ads->first;
        $ad_code .= $ad->html_code;
        
        $ad->update({
            displays => $ad->displays + 1,
        });
    }
    
    $ad_code .= '</p>';

    if ($all_approved) {
	$ad_code .= '</div>';
    }
    
    return $ad_code;
}


sub num_group_join_requests {
    my ( $self, $c ) = @_;
    my $num_requests;
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $cid = "worldofanime:num_group_join_requests:$user_id";
    $num_requests = $c->cache->get($cid);
    
    unless (defined($num_requests)) {
        
        my $UserGroups = WorldOfAnime::Controller::DAO_Groups::GetUserGroups( $c, $user_id );
        
        while (my $group = $UserGroups->next) {
            my $GroupID     = $group->group_id->id;
            my $creator_id  = $group->group_id->group_creator->id;
            
            if ( ($user_id == $creator_id) || ($group->is_admin) ) {
                my $NumJoinRequests = WorldOfAnime::Controller::DAO_Groups::GetNumJoinRequests( $c, $GroupID );
                
                $num_requests += $NumJoinRequests;
            }
        }        

        # Set memcached object for 30 days
	$c->cache->set($cid, $num_requests, 2592000);
    }
    
    return $num_requests;
}


sub get_last_action_date {
    my ($self, $c, $id ) = @_;
    my $last_action_date;
    
    my $Action = $c->model('DB::LastAction')->find( { user_id => $id });
    
    if (defined($Action)) {
        $last_action_date = $Action->lastaction;
    }
    
    return $last_action_date;
}


sub num_threads_by_forum {
    my ( $self, $c, $forum_id ) = @_;

    my $num_threads = WorldOfAnime::Controller::DAO_Forums::FetchThreadsByForum( $c, $forum_id );
    return $num_threads;
}


sub fetch_last_thread {
    my ( $self, $c, $forum_id ) = @_;
    
    my $thread = WorldOfAnime::Controller::DAO_Forums::FetchFirstThreadByForum( $c, $forum_id ) ;
    return $thread;
}


sub num_news_comments {
    my ( $self, $c, $id ) = @_;
    my $num_comments;
    
    my $cid = "worldofanime:num_news_comments:$id";
    $num_comments = $c->cache->get($cid);
    
    unless (defined($num_comments)) {
        
        my $Comments = WorldOfAnime::Controller::DAO_News::GetNewsArticleComments( $c, $id, 0 );
        
            if (defined($Comments)) {
                $num_comments = $Comments->count;
            }

        # Set memcached object for 30 days
	$c->cache->set($cid, $num_comments, 2592000);
    }
    
    return $num_comments;
}


sub prettify_date {
    my ($self, $c, $date, $format, $utz) = @_;

    eval {
        
    $utz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $FormattedDate;
    unless ($utz) { $utz = "America/New_York"; }  # Default time zone
        
    # MySQL's default format;
    # 2011-03-10T21:29:51
    
    $date =~ s/T/ /;

    my $ltz = DateTime::TimeZone->new(name => "America/New_York");  # Local timezone of database

    my $dt = DateTime::Format::MySQL->parse_datetime($date);
    my $tz = DateTime::TimeZone->new(name => $utz);
    
    $dt->subtract(seconds => $ltz->offset_for_datetime($dt));
    $dt->add(seconds => $tz->offset_for_datetime($dt));
    
    my $new_date =  DateTime::Format::MySQL->format_datetime($dt);

    my ($a, $b) = split(/ /, $new_date);
    my ($year, $month, $day)  = split(/\-/, $a);
    my ($hour, $minutes, $seconds) = split(/\:/, $b);
    
    my %date = ('month' => $month,
		'year'  => $year,
		'hour' => $hour,
		'minutes' => $minutes,
		'seconds' => $seconds,
		'day_of_month' => $day);

    $hour =~ s/^0//;
    
    if ($format == 1) {
	# Mar 10, 2011 at 9:29:51 p.m
	
	$month =~ s/^01$/Jan/;
	$month =~ s/^02$/Feb/;
	$month =~ s/^03$/Mar/;
	$month =~ s/^04$/Apr/;
	$month =~ s/^05$/May/;
	$month =~ s/^06$/Jun/;
	$month =~ s/^07$/Jul/;
	$month =~ s/^08$/Aug/;
	$month =~ s/^09$/Sep/;
	$month =~ s/^10$/Oct/;
	$month =~ s/^11$/Nov/;
	$month =~ s/^12$/Dec/;
	
	my $am_or_pm = "AM";

        if ($hour == 12) {
            $am_or_pm = "PM";
        }
        
        if ($hour < 1) {
            $hour = 12;
        }

	if ($hour > 12) {
	    $hour -= 12;
	    $am_or_pm = "PM";
	}
	$FormattedDate = "$month $day, $year $hour:$minutes $am_or_pm";
    }
    
    
    if ($format == 2) {
	# 9:29:51 p.m  - Just the time
	
	my $am_or_pm = "AM";

        if ($hour == 12) {
            $am_or_pm = "PM";
        }
        
        if ($hour < 1) {
            $hour = 12;
        }

	if ($hour > 12) {
	    $hour -= 12;
	    $am_or_pm = "PM";
	}
	$FormattedDate = "$hour:$minutes $am_or_pm";
    }
    
    if ($format == 3) {
	# Mar 10, 2011 - Just the date
	
	$month =~ s/^01$/January/;
	$month =~ s/^02$/February/;
	$month =~ s/^03$/March/;
	$month =~ s/^04$/April/;
	$month =~ s/^05$/May/;
	$month =~ s/^06$/June/;
	$month =~ s/^07$/July/;
	$month =~ s/^08$/August/;
	$month =~ s/^09$/September/;
	$month =~ s/^10$/October/;
	$month =~ s/^11$/November/;
	$month =~ s/^12$/December/;

	$FormattedDate = "$month $day, $year";
    }
    
    
    if ($format == 4) {
	# Mar 10, 2011 at 9:29:51 p.m
	
	# full time
	
	#$FormattedDate =~ s/a.m./AM/;
	#$FormattedDate =~ s/p.m./PM/;
	
	$month =~ s/^01$/Jan/;
	$month =~ s/^02$/Feb/;
	$month =~ s/^03$/Mar/;
	$month =~ s/^04$/Apr/;
	$month =~ s/^05$/May/;
	$month =~ s/^06$/Jun/;
	$month =~ s/^07$/Jul/;
	$month =~ s/^08$/Aug/;
	$month =~ s/^09$/Sep/;
	$month =~ s/^10$/Oct/;
	$month =~ s/^11$/Nov/;
	$month =~ s/^12$/Dec/;
	
	my $am_or_pm = "AM";

        if ($hour == 12) {
            $am_or_pm = "PM";
        }	
	
        if ($hour < 1) {
            $hour = 12;
        }
	
	if ($hour > 12) {
	    $hour -= 12;
	    $am_or_pm = "PM";
	}
	$FormattedDate = "$month $day, $year $hour:$minutes:$seconds $am_or_pm";
    }       
    
    
    return $FormattedDate;

    }; # end eval
}


# Register User Action
sub ra {
    my ( $self, $c ) = @_;

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    $c->model("DB::LastAction")->update_or_create({
	user_id    => $user_id,
	lastaction => undef,
    },
	{ key => 'user_id' }
    );
    
    # Set their online memcached object to true for 30 minutes
    my $cid = "worldofanime:online:$user_id";
    $c->cache->set($cid, 1, 1800);
    
    return undef;
}


sub seconds_ago {
    my ( $self, $c, $date ) = @_;
    
    return 1;
    #return -1 if ($date =~ /0000/);
    
    $date =~ s/T/ /;
    
    #my $dt = DateTime::Format::MySQL->parse_datetime( $date )->set_time_zone( 'America/New_York' );
    #my $dtn = DateTime->now(time_zone=>'America/New_York');
    #my $sec = ($dtn->epoch - $dt->epoch);
    
    #return $sec;
}


sub int {
    my ($self, $c, $num) = @_;
    
    return int($num);
}



sub group_css {
    my ($self, $c, $id) = @_;

    # Try to get css from memcached

    my $cid = "worldofanime:css:group:$id";
    my $css = $c->cache->get($cid);    
    
    # If not, get it and set it
    
    unless ($css) {
        
        $css .= "<style>\n";
        
        my $Group = $c->model('DB::Groups')->find({
            id => $id,
        });
	
        if ($Group) {

            if ($Group->background_image_id) {
		$c->log->info("WE HAVE AN IMAGE!");
                my $scroll   = $Group->scroll_background;
                my $repeat_x = $Group->repeat_x;
                my $repeat_y = $Group->repeat_y;
                
                $scroll =~ s/1/scroll/;
                $scroll =~ s/0/fixed/;
                
                my $repeat;
                
                if ( ($repeat_x) && ($repeat_y) ) {
                    $repeat = "repeat-x repeat-y";
                }
                
                if ( ($repeat_x) && !($repeat_y) ) {
                    $repeat = "repeat-x";
                }                

                if ( !($repeat_x) && ($repeat_y) ) {
                    $repeat = "repeat-y";
                }                

                if ( !($repeat_x) && !($repeat_y) ) {
                    $repeat = "no-repeat";
                }
		
		my $i = $c->model('Images::Image');
		$i->build($c, $Group->background_image_id);
		my $background_url = $i->full_url;
                
                $css .= <<EndOfCSS;
body {
    background-image: url('$background_url');
    background-repeat: $repeat;
    background-attachment: $scroll;    
}
EndOfCSS
        
            }
        }

        $css .= "</style>\n";
        
        #$c->cache->set($cid, $css); 
    }
    
    return $css;
}


sub user_profile_css {
    my ($self, $c, $user) = @_;
    my $user_id;
    
    if ($user) {
	$user =~ s/(\/.*$)//g;
	my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
	$user_id = $u->{'id'};
    } else {
	$user_id = $c->session->{user_id};
    }
    
    # Try to get css from memcached

    my $cid = "woa:css:user:$user_id";
    my $css = $c->cache->get($cid);    
    
    # If not, get it and set it
    
    unless ($css) {
        
        $css .= "<style>\n";

        my $User = $c->model('DB::Users')->find($user_id);
        
        if ($User) {
            if ($User->user_profiles->background_profile_image_id) {
                my $scroll   = $User->user_profiles->scroll_background;
                my $repeat_x = $User->user_profiles->repeat_x;
                my $repeat_y = $User->user_profiles->repeat_y;
                
                $scroll =~ s/1/scroll/;
                $scroll =~ s/0/fixed/;
                
                my $repeat;
                
                if ( ($repeat_x) && ($repeat_y) ) {
                    $repeat = "repeat-x repeat-y";
                }
                
                if ( ($repeat_x) && !($repeat_y) ) {
                    $repeat = "repeat-x";
                }                

                if ( !($repeat_x) && ($repeat_y) ) {
                    $repeat = "repeat-y";
                }                

                if ( !($repeat_x) && !($repeat_y) ) {
                    $repeat = "no-repeat";
                }
		
		my $i = $c->model('Images::Image');
		$i->build($c, $User->user_profiles->background_profile_image_id);
		my $background_url = $i->full_url;
                
                $css .= <<EndOfCSS;
body {
    background-image: url('$background_url');
    background-repeat: $repeat;
    background-attachment: $scroll;
}
EndOfCSS
            }
        }
        
        $css .= "</style>\n";
        
        $c->cache->set($cid, $css);
    }
    
    return $css;
}


sub get_friend_requests {
    my ( $self, $c ) = @_;
    my $num_requests = 0;
    my %SeenFriend;    

    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $cid = "worldofanime:num_friend_requests:$user_id";
    $num_requests = $c->cache->get($cid);
    
    unless (defined($num_requests)) {

        my $FriendRequests = $c->model("DB::UserFriends")->search_literal("user_id = $user_id AND status = 1",
        {
            select   => [qw/friend_user_id/],
            distinct => 1,
        });
        
        if ($FriendRequests) {
            while (my $friend = $FriendRequests->next) {
                next if $SeenFriend{$friend->friend_user_id};
                $SeenFriend{$friend->friend_user_id} = 1;
                $num_requests++;
            }    
        }

        # Set memcached object for 30 days
	$c->cache->set($cid, $num_requests, 2592000);        
    }
    
    return $num_requests;
}


sub get_unread_pms {
    my ( $self, $c ) = @_;
    my $pms = 0;
    
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $cid = "woa:num_unread_pms:$user_id";
    $pms = $c->cache->get($cid);
    
    unless (defined($pms)) {
	
	my $rs = $c->model("DB::PrivateMessages")->search( {
	    -AND => [
		user_id => $user_id,
		is_read => 0,
	    ],
	   });
	
	if (defined($rs)) {

	    $pms = $rs->count;
	    
	    # Set memcached object for 30 days
	    $c->cache->set($cid, $pms, 2592000);
	}
    }
    
    return $pms;
}


sub get_user_profile_image {
    my ( $self, $c, $id ) = @_;
    
    my $p = $c->model('Users::UserProfile');
    $p->build( $c, $id );
    $p->get_profile_image( $c, $id );
    
    return $p;
}


sub show_star_rating {
    my ( $self, $c, $rating) = @_;
    my $html;
    
    my $img_on   = '<img src="/static/images/icons/star-on.png">';
    my $img_off  = '<img src="/static/images/icons/star-off.png">';
    my $img_half = '<img src="/static/images/icons/star-half.png">';
    
    # We are going to receive a rating, between 1 and 10.  We need to convert it to 0 - 5
    # First, divide in half
    $rating = $rating / 2;
    
    if ( ($rating == 0) ) {
	# 0 star
	
	$html = $img_off . $img_off . $img_off . $img_off . $img_off;
    } elsif ( ($rating > 0) && ($rating <= 0.5) ) {
	# 1/2 star

	$html = $img_half . $img_off . $img_off . $img_off . $img_off;
    } elsif ( ($rating > 0.5) && ($rating <= 1.0)) {
	# 1 star

	$html = $img_on . $img_off . $img_off . $img_off . $img_off;	
    } elsif ( ($rating > 1.0) && ($rating <= 1.5)) {
	# 1 1/2 star

	$html = $img_on . $img_half . $img_off . $img_off . $img_off;	
    } elsif ( ($rating > 1.5) && ($rating <= 2.0)) {
	# 2 star

	$html = $img_on . $img_on . $img_off . $img_off . $img_off;	
    } elsif ( ($rating > 2.0) && ($rating <= 2.5)) {
	# 2 1/2 star

	$html = $img_on . $img_on . $img_half . $img_off . $img_off;	
    } elsif ( ($rating > 2.5) && ($rating <= 3.0)) {
	# 3 star

	$html = $img_on . $img_on . $img_on . $img_off . $img_off;	
    } elsif ( ($rating > 3.0) && ($rating <= 3.5)) {
	# 3 1/2 star

	$html = $img_on . $img_on . $img_on . $img_half . $img_off;	
    } elsif ( ($rating > 3.5) && ($rating <= 4.0)) {
	# 4 star

	$html = $img_on . $img_on . $img_on . $img_on . $img_off;	
    } elsif ( ($rating > 4.0) && ($rating <= 4.5)) {
	# 4 1/2 star

	$html = $img_on . $img_on . $img_on . $img_on . $img_half;	
    } elsif ( ($rating > 4.5) && ($rating <= 5.0)) {
	# 5 star

	$html = $img_on . $img_on . $img_on . $img_on . $img_on;	
    }
    
    
    return $html;
}


sub get_profile_comment {
    my ( $c, $id ) = @_;
    
    my $Comment = $c->model('Comments::ProfileComment');
    $Comment->build( $c, $id );
    
    return $Comment;
}



sub display_comment {
    my ( $self, $c, $comment, $format, $fetch_comment_id, $is_self, $is_block ) = @_;
    my $html = GetTemplate($format);

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);    

    # If we were passed a number for comment, we need to fetch a comment object of it first
    if (Scalar::Util::looks_like_number($comment)) {
	$comment = get_profile_comment($c, $comment);
    }
    
    my $comment_id = $comment->id;
    
    my $p = $c->model('Users::UserProfile');
    $p->build( $c, $comment->commenter_id );    
    my $profile_image_id = $p->profile_image_id;
        
    my $i = $c->model('Images::Image');
    $i->build($c, $profile_image_id);
    my $profile_image_url = $i->thumb_url;
        
    my $user_comment = $comment->comment;
    my $username     = $p->username;
    
    my $displayDate   = WorldOfAnime::Controller::Root::PrepareDate($comment->createdate, 1, $tz);    
    
    $user_comment =~ s/\n/<br>/g;    

    # Standard substitutions
    
    $html =~ s/~~ProfileImage~~/$profile_image_url/g;
    $html =~ s/~~Comment~~/$user_comment/g;
    $html =~ s/~~Username~~/$username/g;
    $html =~ s/~~DisplayDate~~/$displayDate/g;
	
    if ($format == 1) {
	if ( $comment_id == $fetch_comment_id ) {
	    $html =~ s/<!--Opening-->/<a name="anchor"><div id="highlighted_post">/g;
	    $html =~ s/<!--Closing-->/<\/div>/g;
	}
	
	if ($is_self) {
	    $html =~ s/<!--Delete-->/<a href="#" class="delete-comment" id="$comment_id"><div id="delete_button">delete<\/div><\/a>/g;
	}
	
	if ($viewer_id) {
	    $html =~ s/~~ExtraClasses~~/comment_$comment_id/g;
	    
	    my $add_reply = <<EndOfHTML;
<div id="setup_reply_$comment_id" style="text-align: right;"><a href="#" class="reply_linky" onclick="javascript:\$('#reply_$comment_id').show();\$('#add_comment #comment_box_$comment_id').focus();\$('#setup_reply_$comment_id').hide();return false">Post a Reply</a></div>

<div id="reply_$comment_id" class="reply_box">
<h2>Post a Reply</h2>
<form id="add_comment" parent="$comment_id" user="$username" latest="latest_reply">
<input type="hidden" name="parent_comment" value="$comment_id">
<textarea id="comment_box_$comment_id" rows="4" cols="44" name="comment_box_$comment_id"></textarea><br clear="all">
<input type="submit" value="Reply" style="float: right; margin-right: 25px; margin-top: 5px; margin-bottom: 5px;" class="removable"><br clear="all">
</form>
</div>
EndOfHTML
	    $html =~ s/<!--AddReply-->/$add_reply/g;	    
	}
    }
	
	
	
    if ($format == 2) {
	my $extra_classes = '';
	
	if ( $comment_id == $fetch_comment_id ) {
	    $extra_classes .= " highlighted";	    
	    $html =~ s/<!--Opening-->/<a name="anchor">/g;
	    #$html =~ s/<!--Closing-->/<\/div>/g;
	}
	
	if ($is_self) {
	    $html =~ s/<!--Delete-->/<a href="#" class="delete-comment" id="$comment_id"><div id="delete_button">delete<\/div><\/a>/g;
	}
	
	if ($viewer_id) {
	    $extra_classes .= " comment_$comment_id";	    	    
	}

	$html =~ s/~~ExtraClasses~~/$extra_classes/g;	    
    }
    
    
    if ($format == 3) {  # Comment reply
	my $extra_classes = '';

	if ( $comment_id == $fetch_comment_id ) {
	    $extra_classes .= " highlighted";
	    $html =~ s/<!--Opening-->/<a name="anchor">/g;
	    #$html =~ s/<!--Closing-->/<\/div>/g;
	}
	
	if ($is_self) {
	    $html =~ s/<!--Delete-->/<a href="#" class="delete-comment" id="$comment_id"><div id="delete_button">delete<\/div><\/a>/g;
	}
	
	if ($viewer_id) {
	    $extra_classes .= " comment_$comment_id";	    
	}

	$html =~ s/~~ExtraClasses~~/$extra_classes/g;	    
    }    
    
    
    return $html;
}


sub GetTemplate {
    my ( $id ) = @_;
    my $template;
    
    if ($id == 1) {
	$template = <<EndOfHTML;
<div class="individual_post ~~ExtraClasses~~">
<!--Opening-->
<!--Delete-->
<a href="/profile/~~Username~~"><img src="~~ProfileImage~~" border="0" class="comment_image"></a>
<span class="post">~~Comment~~</span>
<br clear="all">
<span class="post_byline">Posted by <a href="/profile/~~Username~~">~~Username~~</a> on ~~DisplayDate~~</span>
</div>
<!--Closing-->
<!--Replies-->
<!--AddReply-->
EndOfHTML
    }
    
    
    if ($id == 2) {
	$template = <<EndOfHTML;
<div class="comment squished ~~ExtraClasses~~">
<!--Opening-->
<!--Delete-->
<a href="/profile/~~Username~~"><img src="~~ProfileImage~~"></a>
<p class="article">~~Comment~~</p>
<br clear="all">
<h2>Submitted by <a href="/profile/~~Username~~">~~Username~~</a> on ~~DisplayDate~~</h2><br />
</div>
<!--Closing-->
EndOfHTML
    }
    
    
    if ($id == 3) {
	$template = <<EndOfHTML;
<div class="comment squished reply ~~ExtraClasses~~">
<!--Opening-->
<!--Delete-->
<a href="/profile/~~Username~~"><img src="~~ProfileImage~~"></a>
<p class="article">~~Comment~~</p>
<br clear="all">
<h2>Submitted by <a href="/profile/~~Username~~">~~Username~~</a> on ~~DisplayDate~~</h2><br />
</div>
<!--Closing-->
EndOfHTML
    }        
    
    return $template;
}


sub gallery_info {
    my ( $self, $c, $id ) = @_;
    
    my $Gallery = $c->model('Galleries::Gallery');
    $Gallery->build( $c, $id );
    
    return $Gallery;
}


sub image_info {
    my ( $self, $c, $id ) = @_;
    
    my $Image = $c->model('Images::Image');
    $Image->build( $c, $id );
    
    return $Image;
}


sub pm_mark_read {
    my ( $self, $c, $id ) = @_;
    
    my $PM = $c->model('Messages::PrivateMessage');
    $PM->build( $c, $id );
    $PM->mark_read( $c );
    
    return;
}


sub formatter {
    my ( $self, $c, $text ) = @_;
    
    return $c->model('Formatter')->expand( $text );
}

sub clean_html {
    my ( $self, $c, $text ) = @_;
    
    return $c->model('Formatter')->clean_html( $text );
}



sub create_pager {
    my ( $self, $c, $pager ) = @_;
    my $PagerHTML;

$PagerHTML = <<EndOfHTML;
<div id="pager_line">
[% page_counter_num = 1 %]

[% IF pager.previous_page %]
<a href="[% c.request.uri_with( page => pager.previous_page ) %]">Previous</a>
[% END %]

[% page_count = pager.current_page - 3 %]
[% IF page_count < 1 %]
     [% page_count = 1 %]
[% END %]

[% WHILE page_count <= pager.last_page %]
     [% IF page_counter_num <= 30 %]
          [% IF page_count == pager.current_page %]
          [% page_count %]
          [% ELSE %]
          <a href="[% c.request.uri_with( page => page_count ) %]">[% page_count %]</a>
          [% END %]
     [% END %]
[% page_count = page_count + 1 %]
[% page_counter_num = page_counter_num + 1 %]
[% END %]

[% IF pager.next_page %]
<a href="[% c.request.uri_with( page => pager.next_page ) %]">Next</a>
[% END %]
</div>
EndOfHTML
    
    return $PagerHTML;    
}


sub prettify_text {
    my ( $self, $c, $text ) = @_;
    
    my (@chars) = qw/\` \~ \! \@ \# \$ \% \^ \* \( \) \- \_ \+ \= \| \\\ \? \, \. \[ \{ \] \} \< \> \/ \' \"/;
    
    foreach my $c (@chars) { $text =~ s/$c//g; }
    $text =~ s/\&/ and /g;
    $text =~ s/\s+/_/g;
    $text = lc($text);
    
    return $text;
}


=head1 NAME

WorldOfAnime::View::HTML - Catalyst TTSite View

=head1 SYNOPSIS

See L<WorldOfAnime>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

Daniel

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

