package WorldOfAnime::Controller::Root;

use strict;
use warnings;
use Email::Valid;
use Time::Duration;
use DateTime::Format::MySQL;
use Date::Formatter;
use HTML::Restrict;
use HTML::TagFilter;
use Encode qw/encode decode/;
use JSON;
use List::MoreUtils qw(uniq);
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

sub friend_test :Path('/friend_test') {
    my ( $self, $c ) = @_;
    
    my $friends = WorldOfAnime::Controller::DAO_Friends::GetFriends_JSON( $c, 3 );
    $c->response->body($friends);
}
    

sub index :Path('/') {
    my ( $self, $c ) = @_;
    my @image_ids;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

     # Random Anime
    my $RandomAnimeHTML;
    
    my $r = WorldOfAnime::Controller::DAO_Anime::GetRandomAnime( $c );
    my $title_id    = $r->{'id'};
    my $title       = $r->{'english_title'};
    my $pretty      = $r->{'pretty_title'};
    my $image_id    = $r->{'profile_image_id'};
    my $filedir     = $r->{'filedir'};
    my $filename    = $r->{'filename'};
    my $height      = $r->{'image_height'};
    my $width       = $r->{'image_width'};
    my $description = $r->{'description'};
    my $entered_by  = $r->{'entered_by'};
    
    my $i = $c->model('Images::Image');
    $i->build($c, $image_id);
    my $image_url = $i->thumb_url;	    
    
    push (@image_ids, $image_id);
    
    my $r_link   = "/anime/$title_id/$pretty";
    $description = substr($description, 0, 250);
    $description .= "...";
    
    $filedir =~ s/u\/$/t80\//;
    
    my $link_name = $entered_by;
    $link_name =~ s/ /\%20/g;
    
    $RandomAnimeHTML .= "<h2><a href=\"$r_link\">$title</a></h2>\n";
    $RandomAnimeHTML .= "<a href=\"$r_link\"><img src=\"$image_url\"></a>\n";
    $RandomAnimeHTML .= "$description";
    $RandomAnimeHTML .= "<p class=\"byline\">Entered by <a href=\"/profile/$link_name\">$entered_by</a></p>\n";
    
    # Latest Review
    my ($LatestReviewHTML, $review_image_id) = WorldOfAnime::Controller::DAO_Anime::GetLatestReview( $c );
    push (@image_ids, $review_image_id);

    # Check newest members images for approval
    my $newest = from_json(WorldOfAnime::Controller::API::Users::GetNewestMembers( $self, $c, "code" ));
    foreach my $n (@{ $newest}) {
        push (@image_ids, $n->{profile_image_id});
    }


    # Latest Fan Fiction Activity
    my $LatestFictionActivity;
    
    # Latest Fan Fiction chapter
    my $LatestChapterHTML = WorldOfAnime::Controller::DAO_ArtStory::GetLatestChapter( $c );
    
    $LatestFictionActivity .= $LatestChapterHTML;

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids ) &&
                          WorldOfAnime::Controller::DAO_Images::IsExternalLinksApprovedPreRender( $c, $RandomAnimeHTML ) &&
                          WorldOfAnime::Controller::DAO_Images::IsExternalLinksApprovedPreRender( $c, $LatestReviewHTML );
    $c->stash->{RandomAnimeHTML} = $RandomAnimeHTML;
    $c->stash->{LatestAnimeReview}        = $LatestReviewHTML;
    $c->stash->{LatestFictionActivity}    = $LatestFictionActivity;
    $c->stash->{template} = 'main.tt2';
}


sub latest_activity :Path('/latest/activity') :Args(0) {
    my ( $self, $c ) = @_;
    
    $c->stash->{images_approved} = 1;
    $c->stash->{template} = 'latest_activity.tt2';
}


sub latest_gallery_images :Path('/latest/gallery_images') :Args(0) {
    my ( $self, $c ) = @_;
    my @image_ids;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";    
    
    # Get most recent Image Gallery Image (from someone who says to show to the world)

    my $cid = "worldofanime:latest_gallery_image";
    
    #my $LatestImageGalleryImagesHTML = $c->cache->get($cid);

    ### Removing the caching for now, to be able to check for image approvals
    my $LatestImageGalleryImagesHTML;
    #unless ($LatestImageGalleryImagesHTML) {    
	my $ImageGalleryImages = $c->model('DB::GalleryImages')->search({
	            active     => 1,
			'image_gallery.inappropriate' => 0,
			'image_gallery.show_all' => 1,
		        },{
		    	join     => { 'image_gallery' =>
		    		    },
		        	order_by => { -desc => 'createdate' }
		          })->slice(0, 7);

	$LatestImageGalleryImagesHTML = "<ul class=\"images_horiz\">\n";
	
        while (my $image = $ImageGalleryImages->next) {
		my $displayImageDate = WorldOfAnime::Controller::Root::PrepareDate($image->createdate, 1, $tz);
		
		my $i = WorldOfAnime::Controller::DAO_Images::GetCacheableGalleryImageByID( $c, $image->id );
		my $image_id  = $i->{'id'};
		push (@image_ids, $image_id);
		
		my $Image = $c->model('Images::Image');
		$Image->build($c, $i->{real_image_id});
		my $image_url = $Image->small_url;
		
        	my $image_username = $image->image_gallery->user_galleries->username;
		
		my $tip = "Entered by $image_username<br>$displayImageDate";
		$LatestImageGalleryImagesHTML .= "	<li><a href=\"/profile/$image_username/images/$image_id\"><img src=\"$image_url\" image_desc=\"$tip\"></a></li>";			
	}
	
	$LatestImageGalleryImagesHTML .= "</ul>\n";	    	
	
	#$c->cache->set($cid, $LatestImageGalleryImagesHTML);
    #}

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{latest_gallery_images} = $LatestImageGalleryImagesHTML;    
    $c->stash->{template} = 'latest_gallery_images.tt2';
}


sub whos_on :Path('/online') :Args(0) {
    my ( $self, $c ) = @_;
    my @image_ids;
    my $WhosOnHTML;
    my $count = 0;
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $Members = $c->model("DB::LastAction")->search({
	-and => [
	    'user_profiles.show_visible' => 1,
	    'me.lastaction' => { '>=' => \'now() - interval 30 minute' }
	],
    }, {
        join => { 'user_profiles' => 'last_action' },
        order_by => 'lastaction DESC',
        });
    
    
			while (my $member = $Members->next) {
			    
				# Make sure their memcached object is there
				my $member_id = $member->user_id;
				next unless ( $c->cache->get("worldofanime:online:$member_id") );
				$count++;
				
				my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $member_id );

				my $username   = $u->{'username'};
				my $joindate   = $u->{'joindate'};
				
				my $p = $c->model('Users::UserProfile');
				$p->get_profile_image( $c, $member_id );

				my $profile_image_id = $p->profile_image_id;
				my $height = $p->profile_image_height;
				my $width  = $p->profile_image_width;
				push (@image_ids, $profile_image_id);
				
				my $i = $c->model('Images::Image');
				$i->build($c, $profile_image_id);
				my $profile_image_url = $i->small_url;
				
				my $mult    = ($height / 175);
				my $new_height = int( ($height/$mult) / 1.6 );
				my $new_width  = int( ($width/$mult) / 1.6 );				

			    	my $displayJoindate = WorldOfAnime::Controller::Root::PrepareDate($joindate, 1);
				my $title = "$username<br>Joined $displayJoindate";

				my $tip = "$username<br>Joined $displayJoindate";
				$WhosOnHTML .= "	<a href=\"/profile/$username\"><img src=\"$profile_image_url\" height=\"$new_height\" width=\"$new_width\" image_desc=\"$tip\"></a>";
			}
			
    $WhosOnHTML .= "</ul>\n";
    
    # Did we set a new record with the count?
    
    my ($most_online, $most_online_date) = WorldOfAnime::Controller::DAO_Users::OnlineUsersRecord( $c, $count );

    @image_ids = uniq(@image_ids);

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    $c->stash->{WhosOnHTML}         = $WhosOnHTML;
    $c->stash->{count}              = $count;
    $c->stash->{highest_count}      = $most_online;
    $c->stash->{highest_count_date} = $most_online_date;
    $c->stash->{template}           = 'whos_on.tt2';
}


sub birthdays :Path('/birthday') :Args(0) {
    my ( $self, $c ) = @_;
    
    $c->stash->{template} = 'birthday.tt2';
}


sub top_members :Path('/top') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template}          = 'top_members.tt2';
}


sub announcement :Path('/announcement') :Args(0) {
	my ( $self, $c ) = @_;

	$c->stash->{images_approved} = 1;
	$c->stash->{template} = 'announcement.tt2';
}


sub contact_us :Path('/contact') :Args(0) {
    my ( $self, $c ) = @_;
    
    if (
        ($c->req->param('Message')) &&
        (Email::Valid->address($c->req->param('Email'))) ) {
        
        my $message = $c->req->param('Message');
        my $email   = $c->req->param('Email');
        my $name    = $c->req->param('Name');
        my $subject = "Contact Form: " . $c->req->param('Subject');
        
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', "<$email> $name", $message, $subject);
	
        $c->stash->{contacted} = 1;
    }
    
    $c->stash->{images_approved} = 1;
    $c->stash->{template} = 'contact.tt2';
}


sub report_innapropriate_content :Path('/report_inappropriate_content') {
    my ( $self, $c ) = @_;
    my $body;
    my $details;
    
    my $type = $c->req->params->{'type'};
    my $content = $c->req->params->{'content'};
    
    if ($type eq "profile_image") {
	my $p = $c->model('Users::UserProfile');
	$p->build( $c, $content );
    
	$details = "Inappropriate User Profile Reported\n\n";
	$details .= "User: " . $p->username . "\n";
    }

    if ($type eq "gallery_image") {
	my $i = $c->model('Images::GalleryImage');
	$i->build( $c, $content);
	
	my $owner_id      = $i->owner_id;
	
	my $p = $c->model('Users::UserProfile');
	$p->build( $c, $owner_id );
    
	$details = "Inappropriate User Gallery Image Reported\n\n";
	$details .= "User: " . $p->username . "\n";
	$details .= "Image: " . $content . "\n";
    }

    
    my $from_email = '<meeko@worldofanime.com> World of Anime';
    my $subject = "Inappropriate Content Reported";

    $body = <<EndOfBody;
The following inappropriate content has been reported:

$details
EndOfBody

    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', '<meeko@worldofanime.com> Meeko', $body, $subject);

    $c->response->body("reported");
}


sub terms_of_service :Path('/terms') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{images_approved} = 1;
    $c->stash->{template} = 'terms.tt2';
}


sub about_us :Path('/about') :Args(0) {
    my ( $self, $c ) = @_;
    
    
    $c->stash->{template} = 'about.tt2';
}


sub browse_members :Path('/browse') :Args(0) {
    my ( $self, $c ) = @_;

    my $page = $c->req->params->{'page'} || 1;    

    my $MembersHTML;

    my $Members = $c->model("DB::Users")->search({
        status => 1,
    }, {
	columns   => [qw/ id /],
        order_by  => 'confirmdate DESC',
        page      => "$page",
        rows      => 100,        
        });

    my $pager = $Members->pager();

    $c->stash->{pager}    = $pager;


			while (my $member = $Members->next) {

			    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $member->id );
    
			    my $username   = $u->{'username'};
			    my $joindate   = $u->{'joindate'};
			    
			    my $p = $c->model('Users::UserProfile');
			    $p->get_profile_image( $c, $u->{'id'} );
			    my $profile_image_id = $p->profile_image_id;
			    my $height           = $p->profile_image_height;
			    my $width            = $p->profile_image_width;
			    
			    my $i = $c->model('Images::Image');
			    $i->build($c, $profile_image_id);
			    my $profile_image_url = $i->thumb_url;
    
			    my $mult    = ($height / 80);
			    my $new_height = int( ($height/$mult) / 1.5 );
			    my $new_width  = int( ($width/$mult) /1.5);
			    
			    my $displayJoindate = WorldOfAnime::Controller::Root::PrepareDate($joindate, 1);
			    my $title = "$username<br>Joined $displayJoindate";

				$MembersHTML .= "<div class=\"user_profile_box\">\n";
				$MembersHTML .= "<a href=\"/profile/$username\" title=\"$title\"><img class=\"mini_profile\" src=\"$profile_image_url\" width=\"$new_width\" height=\"$new_height\" border=\"0\"></a>";
				$MembersHTML .= "</div>\n\n";
			}
			
    
    $c->stash->{MembersHTML} = $MembersHTML;    
    $c->stash->{template}    = 'browse.tt2';
}


sub get_comment_template :Path('/comment_template') :Args(1) {
    my ( $self, $c, $id ) = @_;
    my $Body = WorldOfAnime::View::HTML::GetTemplate(2);
    
    $c->response->body($Body);
}


sub robots :Path('/robots.txt') :Args(0) {
    my ( $self, $c ) = @_;
    
    my $robots = "User-agent: Mediapartners-Google 
User-agent: *
Allow: /
Disallow: /admin
Disallow: /moderate
Disallow: /pm
Disallow: /favorites/check_gallery_favorites
";

    $c->response->body("$robots");
}


sub PrepareDate :Local {
    my ($date, $format, $utz) = @_;
    my $FormattedDate;
    
    return unless ($date);
    unless ($format) { $format = 1; } # Default format
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
    
    if ($format == 1) {
	# Mar 10, 2011 at 9:29 p.m
	
	#$FormattedDate   = Date::Formatter->new(%date);
	#$FormattedDate->useShortMonthNames;
	#$FormattedDate->createDateFormatter("(M) (DD), (YYYY) (hh):(mm):(ss) (T)");
	
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


    if ($format == 5) {
	# Mar 10, 2011 at 9:29 p.m
	
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
    
    if ($format == 6) {
	# Mar 10, 2011 - Just the date
	
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

	$FormattedDate = "$month $day, $year";
    }    
    
    return $FormattedDate;
}


sub CleanComment :Local {
    my ( $comment ) = @_;
    
    $comment =~ s/<meta http-equiv=\"Refresh\"(.*)>//gi;
    
    return $comment;
}


sub ResizeComment :Local {
    my ( $comment, $desired_width ) = @_;
    my $old_width;
    my $old_height;
    
    my $new_width;
    my $new_height;
    
    if ($comment =~ /width[=:]["' ]?(\d+)["' ]?/i)  { $old_width = $1; }
    if ($comment =~ /height[=:]["' ]?(\d+)["' ]?/i) { $old_height = $1; }
    
    if ($old_width && $old_height && ($old_width > $desired_width) ) {
	my $mult    = ($old_width / $desired_width);

	$new_height = int( ($old_height/$mult));
	$new_width  = int( ($old_width/$mult));
	
	$comment =~ s/idth[=:]["' ]?(\d+)["' ]?/idth=\"$new_width\"/g;
	$comment =~ s/eight[=:]["' ]?(\d+)["' ]?/eight=\"$new_height\"/g;
	
	$comment = "<br clear=\"all\">\n" . $comment;
    }
    
    
    return $comment;
}


sub get_star_rating :Path('/ajax/star_rating') :Args(1) {
    my ( $self, $c, $rating ) = @_;
    
    my $html = WorldOfAnime::View::HTML::show_star_rating( $self, $c, $rating );
    
    $c->response->body($html);
}


sub CleanKey :Local {
    my ( $key ) = @_;

    $key =~ s/ /+/g;
    $key =~ s/%20/+/g;

    return $key;    
}



# Fetch a UserID given a username  (not in use yet)
sub GetUserID :Local {
    my ( $c, $username ) = @_;
    my $UserID;

    my $cid = "worldofanime:userid:$username";
    $UserID = $c->cache->get($cid);
    
    unless ($UserID) {

	my $User = $c->model("DB::Users")->find({
	    username => $username,
	});

	$UserID = $User->id;
	
	# Set their UserID memcached object for 30 days
	$c->cache->set($cid, 1, 2592000);
    }
    
    return $UserID;
}


# Fetch a profile, given a username
sub GetProfileByID :Local {
    my ( $c, $id ) = @_;
    my @all;
    my $UserProfile;

    my $cid = "worldofanime:profile:$id";
    $UserProfile = $c->cache->get($cid);
    
    unless ($UserProfile) {
	$UserProfile = $c->model('AnimeCacheable::UserProfile')->find({
	    user_id => $id,
        });
	
	$UserProfile->result_class('DBIx::Class::ResultClass::HashRefInflator');
	
	#@all = $UserProfile->all;
	
	 #while (my $hashref = $UserProfile->next) {
	    #push (@{ $all}, $hashref);
	 #}

	# Set their UserID memcached object for 30 days
	#$c->cache->set($cid, 1, 2592000);
	#$c->cache->set($cid, $UserProfile, 60);	
    }
    
    return $UserProfile;
}



sub LoadLatestActivity :Path('/ajax/load_latest_activity') :Args(0) {
    my ( $self, $c ) = @_;
    my @image_ids;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $LatestActivitiesHTML;
    my $LatestActivities;

    if ( ($viewer_id) && ($viewer_id == 3) )  { # Me
	$LatestActivities = $c->model('DB::LatestActivity')->search({},
		{ order_by => 'create_date DESC',
		    rows => 20,
		} );
    } else {
        $LatestActivities = $c->model('DB::LatestActivity')->search({
	    -and => [
        	'user_profiles.show_actions' => 1,
	    ]
        }, {
        	join => { 'users' => { 'user_profiles' } },
		order_by => 'create_date DESC',
		rows => 20,
		});
    }



    while (my $action = $LatestActivities->next) {
    	eval {
	my $id = $action->user_id;
	
	my $user = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $id );
	
	my $username   = $user->{'username'};
	
	my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $id );
        my $profile_image_id = $p->profile_image_id;
	push (@image_ids, $profile_image_id);
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;

	my $ts = $action->create_date;
	$ts =~ s/T/ /;
	my $formatted_date = DateTime::Format::MySQL->parse_datetime( $ts )->set_time_zone( 'America/New_York' );
	my $dtn = DateTime->now(time_zone=>'America/New_York');
	my $sec = ($dtn->epoch - $formatted_date->epoch);
	
	my $description = $c->model('Formatter')->expand( $action->description );
	
	$LatestActivitiesHTML .= "<div class=\"small_info\">\n";
	$LatestActivitiesHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a>";
	$LatestActivitiesHTML .= "<span class=\"action_text\">" . $description . "</span><br />";
	$LatestActivitiesHTML .= "<span class=\"action_text action_time\">" . ago($sec) . "</span>";
	$LatestActivitiesHTML .= "<br clear=\"all\">\n";
	$LatestActivitiesHTML .= "</div>\n";

	} # end eval
    }

    @image_ids = uniq(@image_ids);
    my $approved = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids );
    my $return_json = { 'html' => $LatestActivitiesHTML, 'approved' => $approved };
    $c->response->body(to_json($return_json));
}




sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->status('404');
    $c->stash->{template} = 'not_found.tt2';
}

sub old_end : ActionClass('RenderView') { }

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    my $errors = scalar @{$c->error};

    foreach my $error (@{$c->error}) {
        if ( ($error =~ /.*/) )  # We can use this to forward to different error pages later, if we want
        {
        	my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
		eval {
		    my $e = $c->model('Errors::Error');
		    $e->build($c, $error);
		};
        		
		$c->clear_errors;
		$c->stash->{template} = 'custom_error.tt2';
        }
    }
}


1;
