package WorldOfAnime::Controller::DAO_Email;

use strict;
use MIME::Lite;
use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';


my $send_now = 0;  # 0 to send to waiting emails table
my $ses = 0;


# Send an Email
sub SendEmail :Local {
    my ( $c, $to, $from, $body, $subject ) = @_;
    
    # If this user is suppressed, don't do any of this
    if (!WorldOfAnime::Controller::DAO_Email::IsSuppressed($c, $to)) {

	# We can pass in a $from to send the e-mail from someone, or we can pass in a small numeric value, usually 1
	# If so, we want From to be meeko@worldofanime.com
	
	if (length($from) < 5) {
	    $from = '<meeko@worldofanime.com> World of Anime';
	}
	
	if ($send_now) {
	    my $html_message = &HTMLify($body, $subject, $to);
	    
	    my $msg = MIME::Lite->new(
		From => "$from",
		To => "$to",
		Subject => "$subject",
		Type => 'multipart/alternative'
	    );
    
	    $msg->attach(
		Type => 'text/plain',
		Data => $body,
		);
	
	    $msg->attach(
		Type => 'text/html',
		Data => $html_message,
	    );
	
	    $msg->send_by_smtp('mail.meeko.net');
	    
	} else {
	    
	    my $Email = $c->model("DB::Emails")->create({
		from_email => $from,
		to_email   => $to,
		subject => $subject,
		body => $body,
		is_sent => 0,
		modifydate      => undef,
		createdate      => undef,
	    });
	    
	}
    }
}


# Create a staging Email
sub StageEmail {
    my ( $c, $from_email, $subject, $body, $to_email) = @_;
    
    # Important - We are currently handling suppression of these in the cron job CreateStagedEmail.pl
    # If we ever go to a different e-mail system (like SES), we need to have handle this in code
    
    my $StagingEmail = $c->model('DB::StagingEmails')->create({
	from_email => $from_email,
	subject => $subject,
	body => $body,
	to_email => $to_email,
    });
}


sub IsSuppressed :Local {
    my ( $c, $email ) = @_;
    
    my $Suppression = $c->model('DB::EmailSuppression')->find({
	email => $email,
    });
    
    if ($Suppression) { # User is suppressed
	return 1;
    }
    
    return 0;
}


sub SuppressUser :Local {
    my ( $c, $email ) = @_;
    
    if (!IsSuppressed( $c, $email )) {
	my $Suppression = $c->model('DB::EmailSuppression')->create({
	    email => $email,
	});
    }
}


sub UnSuppressUser :Local {
    my ( $c, $email ) = @_;
    
    if (IsSuppressed( $c, $email )) {
	my $Suppression = $c->model('DB::EmailSuppression')->find({
	    email => $email,
	});
	
	$Suppression->delete;
    }
}


sub IsUser :Local {
    my ( $c, $email ) = @_;
    
    my $User = $c->model('DB::Users')->find({
	email => $email,
    });
    
    if ($User) { # User already exists
	return 1;
    }
    
    return 0;
}


sub IsReferred :Local {
    my ( $c, $email, $UserID ) = @_;
    
    my $Refer = $c->model('DB::Referrals')->find({
	user_id => $UserID,
	referral => $email,
    },
	{ key => 'referral' }
    );
    
    if ($Refer) { # Referral already exists
	return 1;
    }
    
    return 0;
}

# Opt out a user to suppression list
sub OptOut :Local {
    my ( $c, $email ) = @_;
    
    my $Optout = $c->model('DB::EmailSuppression')->update_or_create({
	email => $email,
	modifydate => undef,
	createdate => undef,
    },{ key => 'email' });
}




sub HTMLify {
	my ($message, $subject, $recipient) = @_;
	my $HTML;
	my $extra = "To change which e-mail notifications you receive, log in to your <a href=\"http://www.worldofanime.com/profile\">profile page</a>";

	# Now change the extra text, if the subject warrants it

    if ($subject =~ /You have been invited to join World of Anime/) {

	$extra = "This is a one time e-mail sent to you because your friend thought you would like the site. You are not on a list, but if you would like to ensure you do not receive any more recommendation e-mails, <a href=\"http://www.worldofanime.com/optout/$recipient\">click here</a>";

    }

	$message =~ s/(http\S+)/<a href="$1">$1<\/a>/g;
	$message =~ s/%20/ /g;
	$message =~ s/\n/<p style="margin: 1em 0">/g;

$HTML .= <<EndOfHTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>

<body>
<table style="background-color: #dee8f0; width: 660px;" border="0" cellspacing="0" cellpadding="0" bgcolor="#024c8e" bordercolor="#dee8f0">

<tr align="center">
<td>
&nbsp;
<table style="background-color: #ffffff; width: 600px;" border="0" cellspacing="0" cellpadding="4" align="center" bgcolor="#ffffff">

	<tr>
		<td><a href="http://www.worldofanime.com"><img src="http://www.worldofanime.com/static/images/logo4-small.jpg" width="600" height="114" alt="World of Anime" border="0"></a></td>
	</tr>
	<tr>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td>
	<font size="-1" face="Verdana">
	$message
	</font>
		</td>
	</tr>
	<tr>
		<td><hr size="1" color="grey" width="90%"></td>
	</tr>
	<tr align="center">
		<td><font size="-2" color="grey" face="Arial">$extra</td>
	</tr>
	<tr>
		<td><font size="-2" color="grey" face="Arial">World of Anime<br>
							PO Box 669203<br>
							Marietta, GA 30066</font></td>
	</tr>
</table>
&nbsp;
</td>
</tr>
</table>

</body>
</html>
EndOfHTML

	return $HTML;
}



1;