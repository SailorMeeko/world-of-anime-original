package WorldOfAnime::Controller::Users;

use strict;
use Email::Valid;
use Data::UUID;
use Data::Random qw(:all);
use parent 'Catalyst::Controller';


sub refer :Path('/refer') :Args(1) {
    my ( $self, $c, $referrer ) = @_;
    
   $c->response->redirect("/join?referred_by=$referrer");
   $c->detach();    
}

sub join :Path('/join') {
    my ( $self, $c ) = @_;
    
    $c->stash->{username}    = $c->req->params->{'username'};
    $c->stash->{email}       = $c->req->params->{'email'};
    $c->stash->{referred_by} = $c->req->params->{'referred_by'};
    
    $c->stash->{template} = 'users/join.tt2';
}


sub join_submit :Path('/join_submit') {
    my ( $self, $c ) = @_;
    my $User;
    my $Email;

		# Did they check the terms of service?
		
		unless ($c->req->params->{'terms'}) {
				$c->stash->{alert} = "You must agree to the <a href=\"/terms\" target=\"new_browser\">terms of service</a>.\n";
				$c->detach('join');
		}
		
		# Did they check the age box?
		
		unless ($c->req->params->{'age'}) {
				$c->stash->{alert} = "You must be at least 13 years of age to join World of Anime.\n";
				$c->detach('join');
		}
    		
    
    # First, make sure all the fields have been filled out and are appropriate

    # Remove leading and trailing whitespace
    
    $c->req->params->{'username'} =~ s/^\s+//;
    $c->req->params->{'username'} =~ s/\s+$//;
    
    
    # Username exists
    
    unless ($c->req->params->{'username'}) {
        $c->stash->{alert} = "I'm sorry, you did not enter a username.";
        $c->detach('join');
    }
    
    # Username is 16 or less characters
    
    unless ( length($c->req->params->{'username'}) <= 16) {
        $c->stash->{alert} = "I'm sorry, your username must be 16 or less characters.";
        $c->detach('join');    	
    }

    # Username can not contain bad characters
    my @bad_chars = ( '(',
		      ')',
		      ';',
		      ':',
		      '?',
		      '=',
		      '%',
		      '*',
		      '&',
		      '/',
		      ',',
		      '+');
    
    foreach my $char (@bad_chars) {
	if ($c->req->params->{'username'} =~ /\Q$char\E/) {
	    $c->stash->{alert} = "I'm sorry, your username contains an invalid character.  Please try again";
	    $c->detach('join');  
	}
    }
    
    # E-mail exists and is an e-mail address
    
    unless (Email::Valid->address($c->req->params->{'email'})) {
        $c->stash->{alert} = "I'm sorry, you did not enter a valid e-mail address.";
        $c->detach('join');
    }
    
    # There are 2 passwords entered
    
    unless ( ($c->req->params->{'password'}) && ($c->req->params->{'password2'}) ) {
        $c->stash->{alert} = "I'm sorry, you did not enter something in both password fields.";
        $c->detach('join');
    }
    
    # Password 1 and Password 2 match    

    unless ( ($c->req->params->{'password'}) eq ($c->req->params->{'password2'}) ) {
        $c->stash->{alert} = "I'm sorry, your passwords did not match.";
        $c->detach('join');
    }

    # Now, check to see if the user exists
    
    $User = $c->model("DB::Users")->find({
        username => $c->req->params->{'username'},                                              
    });
    
    if ($User) {
        $c->stash->{alert} = "I'm sorry, that username already exists.";
        $c->detach('join');        
    }


    $User = $c->model("DB::Users")->find({
        email => $c->req->params->{'email'},
    });
    
    if ($User) {
        $c->stash->{alert} = "I'm sorry, that e-mail address already exists.";
        $c->detach('join');        
    }

    
    # Ok, they're good.  Add them

    my $skip = 0;    
    
    ### If their password is super123, they are an evil nasty spam bot
    ### Don't really add them.

    if ($c->req->params->{'password'} eq "super123") {
	$skip = 1;
    }
    
    ### If they are a known spammer, don't really add them either
    
    if (WorldOfAnime::Controller::Helpers::External::IsKnownSpammer( $c, $c->req->address)) {
	$skip = 1;
    }
    

    my $ug   = new Data::UUID;
    my @random_chars1 = rand_chars( set => 'all', min => 25, max => 35 );
    my $random_word1;
    chomp (my $random_word2 = `/bin/date`);
    foreach (@random_chars1) { $random_word1 .= $_; };
    my $uuid = $ug->create_from_name_str("$random_word1", "$random_word2");

    # Were they referred by someone?
    my $referred_by;
    
    if ( $c->req->params->{'referred_by'} ) {
    
	# Figure out this users ID
    
        my $Referral = WorldOfAnime::Controller::DAO_Users::GetUserByUsername($c, $c->req->params->{'referred_by'});
	
	if ($Referral) {
	    $referred_by = $Referral->id;
	}
    }

    unless ($skip) {
        my $NewUser = $c->model("DB::Users")->create({
            uuid        => $uuid,
            username    => $c->req->params->{'username'},
            password    => $c->req->params->{'password'},
            email       => $c->req->params->{'email'},
            status      => 2,
	    referred_by => $referred_by,
            createdate  => undef,
	    join_ip_address  => $c->req->address,
	});
    
	my $NewUserID = $NewUser->id;
    
    
	# Now, create a default User Profile
    
	$c->model("DB::UserProfile")->create({
	    user_id => $NewUserID,
	    show_age => 0,
	    profile_image_id => 14,               # This needs to be the default image_id  (change this later, too)
	    modifydate => undef,
	    createdate => undef,        
	});
    }
    
    
    
    # Now send the user their e-mail

    my $confirm_link = "http://www.worldofanime.com/confirm/$uuid";
    my $username = $c->req->params->{'username'};
    my $subject = "Please confirm your World of Anime registration.";
    
	my $body = <<EndOfBody;
Thank you for signing up for your World of Anime account - the Social Networking site just for anime fans!  Your username for the site is $username

To confirm your registration, you must click on the following Activation Link.  If the link does not work, please cut and paste it into your browser.  If you did not sign up for this account, please ignore this e-mail.  This account will not become active until the Activation Link is clicked on.  Thank you.

$confirm_link
EndOfBody
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $c->req->params->{'email'}, 1, $body, $subject);
    
    $body .= "<p />IP Address: " . $c->req->address;
    
    if ($skip) {
	$body .= "<p>We're skipping this user!</p>\n";
    }

    # And send me a copy too
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, 'Please confirm your World of Anime registration.');
    
    $c->stash->{template} = 'users/join_complete.tt2';
}


sub setup_confirm :Path('/confirm') :Args(0) {
    my ( $self, $c ) = @_;

    my $code = $c->req->param('confirm_code');
    
    if ($code) {
        $c->response->redirect("confirm/$code");
    } else {
        $c->stash->{setup_new} = 1;
        $c->stash->{template} = 'users/confirm.tt2';
    }
}

sub confirm :Path('/confirm') :Args(1) {
    my ( $self, $c, $uuid ) = @_;
    
    # See if this is a real person waiting to be confirmed

    my $User = $c->model("DB::Users")->find({
        uuid => $uuid,
        status => 2
    });
    
    if ($User) {
        $User->update({
            status => 1,
            confirmdate => undef,
        });
        
        # Now, clear out the Newest Members cache, so they will show up
        
        my $redis = $c->model('Redis');
        $redis->client->del("woa/members/newest");
        
        $c->stash->{confirm_success} = 1;


	# Did this person have a referral?
	
	if ($User->referred_by) {
	    
	    my $Referrer = $c->model('DB::Users')->find({
		id => $User->referred_by,
	    });
	    
	    if ($Referrer) {  # Have to do this, in case that user doesn't exist anymore
		
		### Create User Action
    
		my $ActionDescription = "<a href=\"/profile/" . $Referrer->username . "\">" . $Referrer->username . "</a> has referred ";
		$ActionDescription   .= "<a href=\"/profile/" . $User->username . "\">" . $User->username . "</a> to the site!";
    
		my $UserAction = $c->model("DB::UserActions")->create({
		    user_id => $Referrer->id,
		    action_id => 21,
		    action_object => $User->id,
		    description => $ActionDescription,
		    modify_date => undef,
		    create_date => undef,
		});

		### End User Action
		
		# Send an e-mail to the referrer
		
		my $username = $User->username;
		my $subject = "You have referred a new member!";
		my $body = <<EndOfBody;
Congratulations!  A new member who you referred has just joined the site.  Your help in growing the site is greatly appreciated.

You can see the new member who you referred here - http://www.worldofanime.com/profile/$username
EndOfBody

		WorldOfAnime::Controller::DAO_Email::SendEmail($c, $Referrer->email, 1, $body, $subject);
		
		# Send notification

		my $NotifyDescription = "A referral you made, <a href=\"/profile/" . $User->username . "\">" . $User->username . "</a>, has joined the site.";
		
		WorldOfAnime::Controller::Notifications::AddNotification($c, $Referrer->id, $NotifyDescription, 29);
	    }
	    
	}
	
	
	### Create User Action
    
	my $ActionDescription = "<a href=\"/profile/" . $User->username . "\">" . $User->username . "</a> has joined the site!";

	my $UserAction = $c->model("DB::UserActions")->create({
	    user_id => $User->id,
	    action_id => 1,
	    action_object => $User->id,
	    description => $ActionDescription,
	    modify_date => undef,
	    create_date => undef,
        });
    
        ### End User Action
	
	
	
	
    } else {
        $c->stash->{confirm_fail} = 1;
    }
    
    $c->stash->{template} = 'users/confirm.tt2';
}


sub setup_forgot_password :Path('/forgot_password') :Args(0) {
    my ( $self, $c ) = @_;
    my $Email;

    my $email = $c->req->param('email');
    
    if ($email) {
        my $body;
        
        # Figure out who this person is
        
        my $User = $c->model("DB::Users")->find({
            email => $email,
            status => 1,
        });
        
        my $uuid = $User ? $User->uuid : "";
        
        if ($uuid) {
            my $change_link = "http://www.worldofanime.com/change_password/$uuid";
            
            my $username = $User->username;
            
            $body = <<EndOfBody;
We have received a request to change your password for your World of Anime account.  To continue with changing your password, please click on the following link.  If the link does not work, please cut and paste it into your browser.

As a reminder, your username for World of Anime is $username

$change_link

if you did not initiate this request, please ignore this e-mail.
EndOfBody

	    WorldOfAnime::Controller::DAO_Email::SendEmail($c, $c->req->params->{'email'}, 1, $body, 'Password Change Request for World of Anime.');
    
        }
        
        $c->stash->{email_sent} = 1;
    }
    
    $c->stash->{template} = 'users/forgot_password.tt2';
}


sub change_password :Path('/change_password') :Args(1) {
    my ( $self, $c, $uuid ) = @_;

    # Figure out who this person is
        
    my $User = $c->model("DB::Users")->find({
        uuid => $uuid,
    });
    
    my $UserID = $User ? $User->id : "";

    my $password  = $c->req->param('password');
    my $password2 = $c->req->param('password2');

    unless ($UserID) {
        # Not a real user
        
        $c->response->redirect('/');
    }

    if ( ($password) || ($password2) ) {
    
        unless ( ($password)  &&
                 ($password2) &&
                 ($password eq $password2) ) {
            $c->stash->{alert} = "I'm sorry, those passwords don't match.  Try again.";
        } else {
            # Ok, change the password
            
            $User->update({
                password => $password
            });
        
            $c->stash->{changed} = 1;
        }
    }

    $c->stash->{uuid}     = $uuid;
    $c->stash->{template} = 'users/change_password.tt2';
}


sub login :Path('/login') {
    my ( $self, $c ) = @_;
    
    # If already logged in, go to /
    if ($c->user_exists() ) {
	$c->response->redirect('/');
	$c->detach();
    }
    
    if ($c->authenticate( {
            username => $c->req->params->{'username'},
            password => $c->req->params->{'password'},
            status   => 1
        }) ) {

	my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
	
	$c->session->{username} = $c->req->params->{'username'};
	$c->session->{user_id}  = $user_id;
	
	# Set some cookies
	
	my $User = $c->model("DB::Users")->find({
	    id => $user_id,
	});
	
	# Update their last_login_ip_address
	
	$User->update( { last_login_ip_address  => $c->req->address } );
	
	# Create their last_action, and set their online status
	
	$c->model("DB::LastAction")->update_or_create({
	    user_id    => $user_id,
	    lastaction => undef,
	},
	    { key => 'user_id' }
        );
    
	# Set their online memcached object to true for 30 minutes
	my $cid = "worldofanime:online:$user_id";
	$c->cache->set($cid, 1, 1800);
	
	$c->response->cookies->{timezone} = { value => $User->user_profiles->timezone };
	
	# If they are a known spammer, mark them as such, and log them out
	if (!$User->verified_non_spammer) {
	    if (WorldOfAnime::Controller::Helpers::External::IsKnownSpammer( $c, $c->req->address)) {
	        $User->update( { status => 5 } );
	    
	        $c->cache->remove("worldofanime:online:$user_id");	
	        $c->logout();	    
	    } else {
		$User->update( { verified_non_spammer => 1 } );
	    }
	}
	
    } else {
	
	# Create the bad login entry
	$c->model("DB::Logins")->create({
	    is_success => 0,
	    username => $c->req->params->{'username'},
	    password => $c->req->params->{'password'},
	    ip_address => $c->req->address,
	    createdate => undef,
	});
	
	# Forward them to bad login page
	$c->stash->{template} = 'users/bad_login.tt2';
	$c->detach();
    }
    
    # If they came from the confirm screen, take them home (to avoid confusion)
    
    if ( ($c->req->referer =~ /\/confirm\//) ||
         ($c->req->referer =~ /\/login/) ) {
	$c->response->redirect('/');
	  } else {    
    	$c->response->redirect($c->req->referer);
    }
}


sub logout :Path('/logout') {
    my ( $self, $c ) = @_;
    
    if ($c->user_exists() ) {
	
	# Remove their IsOnline memcached object
	
	my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
	$c->cache->remove("worldofanime:online:$user_id");	
	
	# Now, log them out
	
        $c->logout();
    } else {
        $c->stash->{alert} = "Funny.  You weren't logged in to begin with.";
    }
    
    $c->response->redirect($c->req->referer);
}



1;
