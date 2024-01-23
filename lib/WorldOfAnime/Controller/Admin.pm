package WorldOfAnime::Controller::Admin;
use Moose;
use namespace::autoclean;
use Digest::MD5 qw(md5_base64);

BEGIN {extends 'Catalyst::Controller'; }


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
	detach();
    }
    
    my $AdAffiliates = $c->model('DB::AdAffiliates')->search({
    });
    
    my $AdSizes = $c->model('DB::AdSizes')->search({
    });
    
    my $GameCategories = $c->model('DB::GameCategories')->search({ }, { order_by => 'Precedence ASC' });
    my $Games          = $c->model('DB::Games')->search({ }, { order_by => 'createdate DESC' });

    $c->stash->{GameCategories} = $GameCategories;
    $c->stash->{Games} = $Games;
    $c->stash->{AdAffiliates} = $AdAffiliates;
    $c->stash->{AdSizes} = $AdSizes;
    $c->stash->{template} = 'admin/admin.tt2';
}


sub view_memcached :Path('/admin/memcached') :Args(0) {
    my ( $self, $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
	detach();
    }
    
    
    my $newest_ref = $c->cache->get("worldofanime:newest");
    
    $c->stash->{newest_ref} = $newest_ref;
    $c->stash->{template} = 'admin/memcached.tt2';
}

sub remove_memcached_key :Path('/admin/memcached/clear') :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
	detach();
    }
    
    my $key = $c->req->params->{'key'};
    
    if ($key) {
	$c->cache->remove($key);
    }
    
    $c->response->redirect('/admin');  
}

sub remove_memcached_all :Path('/admin/memcached/clear_all') :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
	detach();
    }
    
    $c->cache->clear();

    $c->response->redirect('/admin');  
}

sub add_new_game :Path('/admin/add_new_game') :Args(0) {
    my ( $self, $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
	detach();
    }
    
    
    my $Game = $c->model('DB::Games')->create({
	name        => $c->req->params->{'game_name'},
	pretty_url  => $c->req->params->{'pretty_url'},
	description => $c->req->params->{'description'},
	filename    => $c->req->params->{'filename'},
	image       => $c->req->params->{'imagename'},
	width       => $c->req->params->{'width'},
	height      => $c->req->params->{'height'},
	play_count  => 0,
	game_type   => 1, # Right now we only have Flash Games
	modifydate  => undef,
	createdate  => undef,
    });
    
    my $game_id = $Game->id;

    # Now, the categories
	
    WorldOfAnime::Controller::DAO_Games::AssignGameCategories( $c, $game_id );
    
    $c->response->redirect('/admin');    
}


sub edit_game :Path('/admin/edit_game') :Args(0) {
    my ( $self, $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
	detach();
    }
    
    my $game_id = $c->req->params->{'game_id'};
    
    if ($c->req->params->{'edit'}) {
	# Make the actual edit
	
	my $Game = $c->model('DB::Games')->find({ id => $game_id, });
	
	# First, the regular game
	if ($Game) {
	    $Game->update({
		name        => $c->req->params->{'game_name'},
		pretty_url  => $c->req->params->{'pretty_url'},
		embedurl    => $c->req->params->{'embedurl'},
		filename    => $c->req->params->{'filename'},
		image       => $c->req->params->{'imagename'},
		width       => $c->req->params->{'width'},
		height      => $c->req->params->{'height'},
		description => $c->req->params->{'description'},
	    });
	}
	
	# Now, the categories
	
	WorldOfAnime::Controller::DAO_Games::EmptyGameCategories( $c, $game_id );
	WorldOfAnime::Controller::DAO_Games::AssignGameCategories( $c, $game_id );
	
	
	$c->response->redirect('/admin'); 
	    
    } else {
	# Setup the edit form
	
	my $Game = $c->model('DB::Games')->find({ id => $game_id, });
	my $GameCategories = $c->model('DB::GameCategories')->search({ }, order_by => 'Precedence ASC' );
	
	$c->stash->{Game} = $Game;
	$c->stash->{Categories} = $GameCategories;
	$c->stash->{template} = 'admin/edit_game.tt2';
    }

}


sub create_new_ad :Path('/admin/create_new_ad') :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
	$c->detach();
	detach();
    }    


    my $affiliate   = $c->req->params->{'affiliate'};
    my $ad_size     = $c->req->params->{'ad_size'};
    my $html_code   = $c->req->params->{'html_code'};
    my $description = $c->req->params->{'description'};
    
    my $Ad = $c->model('DB::Ads')->create({
	affiliate_id => $affiliate,
	size_id => $ad_size,
	html_code => $html_code,
	description => $description,
	modify_date => undef,
	create_date => undef,
    });

    $c->response->redirect('/admin');    
}


sub setup_announcement :Path('/admin/setup_announcement') :Args(0) {
    my ( $self, $c ) = @_;
    my $html;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    $html .= <<EndOfHTML;
<form action="/admin/create_announcement" method="post">
Subject: <input type="text" name="subject" size="50"><p />
<textarea name="announcement" cols="95" rows="20"></textarea>
<p />
<input type="Submit" value="Send Announcement!">
</form>    
EndOfHTML

    $c->stash->{content}  = $html;
    $c->stash->{template} = 'admin/announcements.tt2';
}


sub create_announcement :Path('/admin/create_announcement') :Args(0) {
    my ( $self, $c ) = @_;
    my $body    = $c->req->params->{'announcement'};
    my $subject = $c->req->params->{'subject'};

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    
    # First, get everyone who wants announcements
    
    my $Users = $c->model("DB::Users")->search({
		    	'user_profiles.notify_announcements' => 1,
			status => 1,
		        },{
		    	join     => { 'user_profiles' },
	          });
    
    # Next, add a new entry to the Email table
       
    while (my $u = $Users->next) {

	# Create Email here
	
	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $u->email, 1, $body, $subject);
    }
    

    my $html = "Announcement sent!";    
    
    $c->stash->{content} = $html;
    $c->stash->{template} = 'admin/announcements.tt2'; 
    
}



sub link_categories :Path('/admin/link_categories') :Args(1) {
    my ( $self, $c, $id ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    # Get all link categories and subcategories

    my $Category = $c->model('DB::LinksCategories')->find({
	id => $id,
    });
    
    my $cat_name = $Category->name;
    
    until ($Category->parent_category_id == 0) {
	$Category = $c->model('DB::LinksCategories')->find({
	    id => $Category->parent_category_id,
	});
	
	$cat_name = "<a href=\"/admin/link_categories/" . $Category->id . "\">" . $Category->name . "</a> -> " . $cat_name;
    }
    
    my $html;

    $html .= "<h1 class=\"front_header\">$cat_name</h1>\n";

    $html .= "<form action=\"/admin/add_link_subcategory/$id\" method=\"post\">\n";
    $html .= "<table>\n";
    $html .= "<tr>\n";
    $html .= "	<td>Name:</td>\n";
    $html .= "	<td><input type=\"text\" size=\"35\" name=\"category_name\"></td>\n";
    $html .= "</tr>\n";
    $html .= "<tr>\n";
    $html .= "	<td>Description:</td>\n";
    $html .= "	<td><textarea name=\"category_description\" rows=\"6\" cols=\"45\"></textarea></td>\n";
    $html .= "</tr>\n";
    $html .= "</table>\n";
    $html .= "<input type=\"Submit\" value=\"Add New Subcategory Here\">\n";
    $html .= "</form>\n";
    
    $html .= "<p />\n";
    
    my $Categories = $c->model("DB::LinksCategories")->search({
	parent_category_id => $id,
    });
    
    
    while (my $cat = $Categories->next) {
	my $cat_id = $cat->id;
	my $cat_name = $cat->name;
	$html .= "<a href=\"/admin/link_categories/$cat_id\">$cat_name</a>\n";
    }

    $c->stash->{category_tree} = $html;		
    $c->stash->{template} = 'admin/links.tt2';
}


sub add_link_subcategory :Path('/admin/add_link_subcategory') :Args(1) {
    my ( $self, $c, $id ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }

    my $name = $c->req->params->{'category_name'};
    my $description = $c->req->params->{'category_description'};
    
    $c->model('DB::LinksCategories')->create({
	parent_category_id => $id,
	name => $name,
	description => $description,
	modifydate => undef,
	createdate => undef,
	num_links => 0,
	num_subcategories => 0,
    });
    
    my $Category = $c->model('DB::LinksCategories')->find({
	id => $id,
    });
    
    $Category->update({
	num_subcategories => $Category->num_subcategories + 1,
    });


    $c->response->redirect("/admin/link_categories/$id");
}


sub setup_image_verification :Path('/admin/setup_image_verification') :Args(1) {
    my ( $self, $c, $num_images ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    

    # Get some unverified images    
    my $Images = $c->model('DB::Images')->search( {
	    is_appropriate => 0,
	}, {
	    join => 'user_profile_image',
	    select => ['me.id as id', 'user_profile_image.id as profile_image_id'],
	    as => [ 'id', 'profile_image_id' ],
	    rows => $num_images,
	    order_by => 'profile_image_id DESC, create_date DESC',
	   });
    
    $c->stash->{Images} = $Images;
    $c->stash->{template} = 'admin/setup_image_verification.tt2';
}


sub verify_images: Path('/admin/verify_images') :Args(0) {
    my ( $self, $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my @images = split(/,/, $c->req->params->{'check_images'});
    
    foreach my $image_id (@images) {
	next unless $image_id;
	
	my $appropriate = 0;
	my $i = $c->model('Images::Image');
        $i->build($c, $image_id);
	
	if ($c->req->params->{"is_appropriate_$image_id"}) {
	    $appropriate = 1;
	} else {
	    $appropriate = 2;
	}
	
	my $Image = $c->model('DB::Images')->find( $image_id );
	$Image->update({ is_appropriate => $appropriate });
	
	$i->clear( $c );
    }
    
    
    $c->response->redirect("/admin");
}


sub setup_external_image_verification :Path('/admin/setup_external_image_verification') :Args(1) {
    my ( $self, $c, $num_images ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    

    # Get some unverified images    
    my $Images = $c->model('DB::ExternalImages')->search( {
	    is_approved => 0,
	}, {
	    rows => $num_images,
	    order_by => 'id DESC',
	   });
    
    $c->stash->{Images} = $Images;
    $c->stash->{template} = 'admin/setup_external_image_verification.tt2';
}


sub verify_external_images: Path('/admin/verify_external_images') :Args(0) {
    my ( $self, $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my @images = split(/,/, $c->req->params->{'check_images'});
    
    foreach my $image_id (@images) {
	next unless $image_id;
	
	my $approved = 0;
	my $i = $c->model('Images::ExternalImages');
	
	if ($c->req->params->{"is_approved_$image_id"}) {
	    $approved = 1;
	} else {
	    $approved = 2;
	}
	
	my $Image = $c->model('DB::ExternalImages')->find( $image_id );
	$Image->update({ is_approved => $approved });
	
	# Now that we've approved, or denied, update the cache with this info
	my $cid = md5_base64("woa:external_image:$image_id");
	$c->cache->set($cid, $approved, 2592000);
    }
    
    
    $c->response->redirect("/admin");
}


sub setup_external_links_verification :Path('/admin/setup_external_link_verification') :Args(1) {
    my ( $self, $c, $num_images ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    

    # Get some unverified images    
    my $Links = $c->model('DB::ExternalLinks')->search( {
	    is_approved => 0,
	}, {
	    rows => $num_images,
	    order_by => 'id DESC',
	   });
    
    $c->stash->{Links} = $Links;
    $c->stash->{template} = 'admin/setup_external_link_verification.tt2';
}


sub verify_external_links: Path('/admin/verify_external_links') :Args(0) {
    my ( $self, $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my @links = split(/,/, $c->req->params->{'check_links'});
    
    foreach my $link_id (@links) {
	next unless $link_id;
	
	my $approved = 0;
	my $l = $c->model('Images::ExternalLinks');
	
	if ($c->req->params->{"is_approved_$link_id"}) {
	    $approved = 1;
	} else {
	    $approved = 2;
	}
	
	my $Link = $c->model('DB::ExternalLinks')->find( $link_id );
	$Link->update({ is_approved => $approved });
	
	# Now that we've approved, or denied, update the cache with this info
	my $cid = md5_base64("woa:external_link:$link_id");
	$c->cache->set($cid, $approved, 2592000);
    }
    
    
    $c->response->redirect("/admin");
}



sub check_images_appropriate: Path('/admin/check_images_appropriate') :Args(0) {
    my ( $self, $c ) = @_;
    
    my $image_ids = $c->req->params->{'image_ids'};
    
    WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, $image_ids );
}





### Ad Stuff

sub add_new_affiliate :Path('/admin/add_new_affiliate') :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my $name = $c->req->params->{'name'};
    
    $c->model('DB::AdAffiliates')->update_or_create({
	name => $name,
	modify_date => undef,
	create_date => undef,
    },{ key => 'name' });
    
    
    $c->response->redirect('/admin');
}


sub add_new_ad_size :Path('/admin/add_new_ad_size') :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my $name = $c->req->params->{'size_desc'};
    
    $c->model('DB::AdSizes')->create({
	size_desc => $name,
	modify_date => undef,
	create_date => undef,
    });
    
    
    $c->response->redirect('/admin');
}





### Temporary Stuff


sub process_all_actions :Path('/admin/process_all_actions') :Args(0) {
    my ( $self, $c ) = @_;

    # Since we only want to run this once, we are now going to immediately redirect without doing anything
    # If you ever are crazy and really do want to run this again, comment the following line out
    $c->response->redirect('/admin');
    
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    

    # First, remove everyone's actions
    
    my $UserActions = $c->model('DB::UserActions')->search( { } );
    
    while (my $a = $UserActions->next) {
	$a->delete;
    }
    
    
    
    # Now, get all Joins
    
    if (1) {
	my $Joins = $c->model('DB::Users')->search( { status => 1 });
	
	while (my $j = $Joins->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $j->username . "\">" . $j->username . "</a> has joined the site!";

	    my $UserAction = $c->model("DB::UserActions")->create({
	        user_id => $j->id,
	        action_id => 1,
	        action_object => $j->id,
	        description => $ActionDescription,
	        modify_date => $j->modifydate,
	        create_date => $j->createdate,
            });

            ### End User Action	
        }
    }
    
    
    # Now, get all User Profile comments
    
    if (1) {
	my $Comments = $c->model('DB::UserComments')->search( { } );
	
	while (my $comment = $Comments->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $comment->commentors->username . "\">" . $comment->commentors->username . "</a> posted a comment on ";
	    $ActionDescription   .= "<a href=\"/profile/" . $comment->users->username . "\">" . $comment->users->username . "'s</a> profile";

	    my $UserAction = $c->model("DB::UserActions")->create({
		user_id => $comment->commentors->id,
		action_id => 2,
		action_object => $comment->users->id,
		description => $ActionDescription,
		modify_date => $comment->modifydate,
		create_date => $comment->createdate,
	    });

        ### End User Action
	}
    }
    
    
    # Now, get all pictures posted
    
    if (1) {
	my $Images = $c->model('DB::GalleryImages')->search( { } );
	
	while (my $i = $Images->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $i->image_gallery->user_galleries->username . "\">" . $i->image_gallery->user_galleries->username . "</a> posted a ";
	    $ActionDescription   .= "<a href=\"/profile/" . $i->image_gallery->user_galleries->username . "/images/" . $i->id . "\">new image</a> in their image gallery";

	    my $UserAction = $c->model("DB::UserActions")->create({
        	user_id => $i->image_gallery->user_galleries->id,
        	action_id => 3,
        	action_object => $i->id,
        	description => $ActionDescription,
        	modify_date => $i->modifydate,
        	create_date => $i->createdate,
	    });
    
	}
    }
    
    
    # Now, get all forum threads
    
    if (1) {
	my $Threads = $c->model('DB::ForumThreads')->search( { } );
	
	while (my $t = $Threads->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $t->started_by_user_id->username . "\">" . $t->started_by_user_id->username . "</a> created a ";
	    $ActionDescription   .= "<a href=\"/forums/thread/" . $t->id . "\">new thread</a> in the forums";

	    my $UserAction = $c->model("DB::UserActions")->create({
		user_id => $t->started_by_user_id->id,
		action_id => 4,
		action_object => $t->id,
		description => $ActionDescription,
		modify_date => $t->modify_date,
		create_date => $t->create_date,
	    });

	    ### End User Action
	}
    }
    
    
    # Now, get all forum posts
    
    if (1) {
	my $Posts = $c->model('DB::ThreadPosts')->search( { } );
	
	while (my $p = $Posts->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $p->user_id->username . "\">" . $p->user_id->username . "</a> posted a ";
	    $ActionDescription   .= "<a href=\"/forums/thread/" . $p->thread_id->id . "\">new comment</a> in the forums";

	    my $UserAction = $c->model("DB::UserActions")->create({
	    	user_id => $p->user_id->id,
		action_id => 5,
		action_object => $p->thread_id->id,
		description => $ActionDescription,
		modify_date => $p->modify_date,
		create_date => $p->create_date,
	    });

	    ### End User Action
	}
    }
    
    
    
    # Now, get all Gallery Image Comments
    
    if (1) {
	my $GalleryImageComments = $c->model('DB::GalleryImageComments')->search( { } );
	
	while (my $ic = $GalleryImageComments->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $ic->image_commentor->username . "\">" . $ic->image_commentor->username . "</a> posted a comment on an ";
	    $ActionDescription   .= "<a href=\"/profile/" . $ic->gallery_image_id->image_gallery->user_galleries->username . "/images/" . $ic->gallery_image_id . "\">image</a> in ";
	    $ActionDescription   .= "<a href=\"/profile/" . $ic->gallery_image_id->image_gallery->user_galleries->username . "\">" . $ic->gallery_image_id->image_gallery->user_galleries->username . "'s</a> image gallery";
    
	    my $UserAction = $c->model("DB::UserActions")->create({
	      	user_id => $ic->image_commentor->id,
	        action_id => 6,
	        action_object => $ic->gallery_image_id,
		description => $ActionDescription,
		modify_date => $ic->modifydate,
		create_date => $ic->createdate,
	    });

	    ### End User Action
	}
    }



    # Now, get all new blog entries
    
    if (1) {
	my $BlogEntries = $c->model('DB::Blogs')->search( { } );
	
	while (my $b = $BlogEntries->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $b->blog_user->username . "\">" . $b->blog_user->username . "</a> posted a new ";
	    $ActionDescription   .= "<a href=\"/blogs/" . $b->blog_user->username . "/" . $b->id . "\">blog entry</a>";
    
	    my $UserAction = $c->model("DB::UserActions")->create({
		user_id => $b->blog_user->id,
		action_id => 7,
		action_object => $b->id,
		description => $ActionDescription,
		modify_date => $b->modifydate,
		create_date => $b->createdate,
	    });

	    ### End User Action
	}
    }
    
    
    # Now, get all blog comments
    
    if (1) {
	my $BlogComments = $c->model('DB::BlogComments')->search( { } );
	
	while (my $bc = $BlogComments->next) {
	    ### Create User Action
    
	    my $ActionDescription = "<a href=\"/profile/" . $bc->blog_commentor->username . "\">" . $bc->blog_commentor->username . "</a> posted a comment on ";
	    $ActionDescription   .= "<a href=\"/blogs/" . $bc->blog->blog_user->username . "/" . $bc->blog->id . "\">" . $bc->blog->blog_user->username . "'s Blog</a>";

	    my $UserAction = $c->model("DB::UserActions")->create({
		user_id => $bc->blog_commentor->id,
		action_id => 8,
		action_object => $bc->blog->id,
		description => $ActionDescription,
		modify_date => $bc->modifydate,
		create_date => $bc->createdate,
	    });

	    ### End User Action
	}
    }
    
    
    $c->response->redirect('/admin');
}


sub count_all_gallery_images :Path('/admin/count_all_gallery_images') :Args(0) {
    my ( $self, $c ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my $Galleries = $c->model('DB::Galleries')->search({
							  });
    
    while (my $gallery = $Galleries->next) {
	
	WorldOfAnime::Controller::DAO_Images::CountGalleryImages( $c, $gallery->id );
	
    }


    $c->response->redirect('/admin');
}



sub update_gallery_settings :Path('/admin/update_gallery_settings') :Args(0) {
    my ( $self, $c ) = @_;

    # Since we only want to run this once, we are now going to immediately redirect without doing anything
    # If you ever are crazy and really do want to run this again, comment the following line out
    $c->response->redirect('/admin');
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my $Galleries = $c->model('DB::Galleries')->search({
							  });
    
    while (my $gallery = $Galleries->next) {
	# Figure out what their current gallery setting is
	
	my $UserProfile = $c->model('DB::UserProfile')->find({
	    user_id => $gallery->user_id,
	});
	
	# Update Gallery with current setting
	
	$gallery->update({
	    show_all => $UserProfile->show_gallery_to_all,
	});
	
    }


    $c->response->redirect('/admin');
}


sub update_lastaction :Path('/admin/update_last_action') :Args(0) {
    my ( $self, $c ) = @_;

    # Since we only want to run this once, we are now going to immediately redirect without doing anything
    # If you ever are crazy and really do want to run this again, comment the following line out
    $c->response->redirect('/admin');
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    my $Users = $c->model('DB::Users')->search({
	lastaction => \'> 2011-01-01',
    });
    
    if (0) {
        while (my $user = $Users->next) {
            $c->model("DB::LastAction")->update_or_create({
        	user_id    => $user->id,
        	lastaction => $user->lastaction,
	    },
	        { key => 'user_id' }
	    );
	}
    }
}


sub resubscribe_blogs :Path('/admin/resubscribe_blogs') :Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }

    # Get all current blog entry subscriptions
    
    my $Subs = $c->model('DB::BlogSubscriptions')->search({
    });
    
    while (my $s = $Subs->next) {
	
	my $blog_user_id = $s->blog_id->user_id;
	
	unless ($s->user_id == $blog_user_id) {
	    $c->model('DB::BlogUserSubscriptions')->update_or_create({
	        subscriber_user_id => $s->user_id,
	        subscribed_to_user_id => $blog_user_id,
	        modify_date => undef,
	        create_date => undef,
	    });
	}
    }
    
    $c->response->redirect('/admin');
}


sub convert_local_image_to_s3: Path('/admin/convert_image_to_s3') :Args(1) {
    my ( $self, $c, $num ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    # Grab X number of images is_s3 = 0 order by create_date DESC
    
    my $Images = $c->model('DB::Images')->search({
	id => { '>' => 14 },
	is_s3 => 0,
    },{
       rows => $num,
       order_by => 'create_date DESC'
      });
    
    while (my $i = $Images->next) {
	my $id = $i->id;
	my $filedir = $i->filedir;
	
	# Old version of images allowed overwriting images with the same name, so we want to only process the most recent one if this occurs, which is
	# why we are ordering descending.
	# Check if the file exists on disk.  If not, delete the record from the table.  Oh well.

	if ($filedir eq "static/images/u/") { $filedir = "u"; }
        if ($filedir eq "static/images/backgrounds/profile/") { $filedir = "backgrounds/profile"; }
        if ($filedir eq "static/images/backgrounds/groups/") { $filedir = "backgrounds/groups"; }
        if ($filedir eq "static/images/news/") { $filedir = "news"; }

	my $orig_dir = $c->config->{baseimagefiledir} . $filedir;
	
	my $file = $orig_dir . "/" . $i->filename;
	
	if (-e $file) {
	    # Upload the image from disk to S3 using new upload_s3 method (to update image instead of create new)
	    
	    my $newfilename = WorldOfAnime::Controller::DAO_Images::upload_local_image_s3($c, $i->filedir, $i->filename, $i->filetype);
    
	    # Update image
	    
	    $i->update({ is_s3 => 1, filedir => 'images.worldofanime.com/u', filename => $newfilename });
	    
	    # Delete the cache of this image
	    
	    $c->cache->remove("woa:image:$id");
	} else {
	    $i->delete;
	}
    }
    
    $c->response->body('Done.');
}


sub cancel_account :Path('/admin/cancel_account') :Args(1) {
    my ( $self, $c, $user ) = @_;
    
    unless ($c->user_exists() && $c->check_user_roles( qw/ is_admin / ) ) {
	$c->stash->{error_message} = "You must be an admin to be here.";
	$c->stash->{template}      = 'error_page.tt2';
        $c->detach();
	detach();
    }
    
    # Get user ID
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByUsername( $c, $user );
    my $user_id   = $u->{'id'};
    my $email     = $u->{'email'};
    
    # Remove friendships
    my $Friends = $c->model("DB::UserFriends")->search({
	    user_id => $user_id,
    });
    my $UserFriends = $c->model("DB::UserFriends")->search({
	    friend_user_id => $user_id,
    });    
    
    $Friends->delete;
    $UserFriends->delete;

    # Get blogs
    my $Blogs = $c->model("DB::Blogs")->search({ user_id => $user_id, });
    
    # Delete blog comments made and received
    while (my $b = $Blogs->next) {
	$b->blog_comments->delete;
	$b->blog_subscriptions->delete;
    }
    
    my $BlogCommentsMade = $c->model('DB::BlogComments')->search({ user_id => $user_id, });
    $BlogCommentsMade->delete;
    
    # Delete blogs
    $Blogs->delete;

    # Get all Galleries
    my $Galleries = $c->model('DB::Galleries')->search({ user_id => $user_id, });
    
    while (my $g = $Galleries->next) {
	# Get all images from all galleries
	my $GalleryImages = $g->gallery_images;
	
	while (my $i = $GalleryImages->next) {
	    # Delete image comments received
	    $i->gallery_image_comments->delete;
	    # Delete image from all favorites lists
	    $i->gallery_image_favorites->delete;
	    # Set to not active
	    $i->update({ active => 0 });
	}
	
	$g->delete;
    }
    
    # Delete all image comments made
    my $ImageComments = $c->model('DB::GalleryImageComments')->search({ comment_user_id => $user_id, });
    $ImageComments->delete;
    
    # Remove all gallery images favorites
    my $GalleryImageFavorites = $c->model('DB::FavoritesGalleryImages')->search({ user_id => $user_id, });
    $GalleryImageFavorites->delete;
    

    ##### NOTE - This needs to change logic when we do collobarative fan fiction
    #          - We don't want someone removing their account to remove the entire fan fiction
    #          - Just change the chapter to "unknown user"
    # Get all fan fiction started
    my $ArtStoriesStarted = $c->model('DB::ArtStoryTitle')->search({
	-and => [
	    started_by_user_id => $user_id,
	    story_mode => 1,
	],
    });
    
    while (my $s = $ArtStoriesStarted->next) {
	# Get chapters
	my $Chapters = $s->chapters;
	
	while (my $chap = $Chapters->next) {
	    # Delete comments
	    $chap->comments->delete;
	    # Delete chapter
	    $chap->delete;
	}

	# Delete fan fiction
	$s->delete;
    }

    # Delete fan fiction comments made
    my $ArtStoryCommentsMade = $c->model('DB::ArtStoryComments')->search({ user_id => $user_id, });
    $ArtStoryCommentsMade->delete;
    

    # Delete all profile comments made and received
    my $ProfileComments = $c->model('DB::UserComments')->search({
	    user_id => $user_id,
    });
    my $ProfileCommentsMade = $c->model('DB::UserComments')->search({
	    comment_user_id => $user_id,
    });    
    $ProfileComments->delete;
    $ProfileCommentsMade->delete;
    
    # Delete all group comments made
    my $GroupComments = $c->model('DB::GroupComments')->search({ comment_user_id => $user_id, });
    $GroupComments->delete;
    
    my $GroupCommentReplies = $c->model('DB::GroupCommentReplies')->search({ comment_user_id => $user_id, });
    $GroupCommentReplies->delete;

    # Remove user from all groups
    my $UserGroups = $c->model('DB::GroupUsers')->search({ user_id => $user_id, });
    $UserGroups->delete;
    
    # Delete all anime answers given
    my $Answers = $c->model('DB::QAAnswers')->search({ answered_by => $user_id, });
    $Answers->delete;

    ## Delete all notifications
    #my $Notifications = $c->model('DB::Notifications')->search({ user_id => $user_id, });
    #$Notifications->delete;
    #
    ## Delete all actions
    #my $UserActions = $c->model('DB::UserActions')->search({ user_id => $user_id, });
    #$UserActions->delete;
    
    # Delete all questions asked, their subscriptions, and their answers
    my $Asked = $c->model('DB::QAQuestions')->search({ asked_by => $user_id, });
    while (my $a = $Asked->next) {
	$a->qa_subscriptions->delete;
	$a->qa_answers->delete;
	$a->delete;
    }
    
    # Delete all forums posts given
    my $ThreadPosts = $c->model('DB::ThreadPosts')->search({ user_id => $user_id, });
    $ThreadPosts->delete;
    
    # Delete all forum topics started, their subscriptions, and their thread_posts
    my $ThreadsStarted = $c->model('DB::ForumThreads')->search({ started_by_user_id => $user_id, });
    while (my $t = $ThreadsStarted->next) {
	$t->thread_subscriptions->delete;
	$t->thread_posts->delete;
	$t->delete;
    }
    
    # Delete all their QA Subscriptions
    my $QASubs = $c->model('DB::QASubscriptions')->search({ user_id => $user_id, });
    $QASubs->delete;

    my $User = $c->model('DB::Users')->find($user_id);
    
    # Delete all their Blog Subscriptions
    $User->user_blog_subscriptions->delete;
    
    # Delete all their thread subscriptions
    $User->user_thread_subscriptions->delete;
    
    # Delete all their notifications
    $User->user_notifications->delete;
    
    # Delete all their actions
    $User->user_actions->delete;
    
    # Delete all their ArtStory Subscriptions
    $User->art_story_subscriptions->delete;
    
    # Delete all their Favorites
    $User->favorite_gallery_images->delete;

    # Change their status to 4
    $User->update({
	status=> 4,
    });

    # Change their e-mail address to append _REMOVED
    my $new_email = $email . "_REMOVED";
    
    $User->update({
	email => $new_email,
    });

    $c->response->redirect('/admin');
}


__PACKAGE__->meta->make_immutable;

