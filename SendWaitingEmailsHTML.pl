#!/usr/bin/perl

BEGIN {
        push @INC, "/var/www/crons";
}

use DBConnector;
use MIME::Lite;

my %databases = ( "worldofanime", "" );


foreach my $k (keys %databases) {

	my $DBCon = DBConnector->new();
	my $dbh   = $DBCon->GetConn($k, $databases{$k});

	# Get all waiting e-mails

	my $Emails = &GetEmails($dbh);

	foreach my $e (@{ $Emails} ) {
		&Send($e->{subject}, $e->{body}, $e->{to_email}, $e->{from_email});
	}

}



sub GetEmails {
	my ($dbh) = @_;
	my $all;

	my $sql = "SELECT * FROM emails WHERE is_sent = 0";

	my $sth = $dbh->prepare($sql);

	$sth->execute();

	while (my $ref = $sth->fetchrow_hashref) {
		push (@{ $all}, $ref);

		# For testing, we want to archive off every e-mail that doesn't go to me, for testing later
		if ($ref->{to_email} =~ /meeko/) {
			&Delete($dbh, $ref->{id});
		} else {
                        &Delete($dbh, $ref->{id});
			#&SetStatus($dbh, $ref->{id}, 3);
		}

	}

	return $all;
}


sub SetStatus {
	my ($dbh, $id, $status) = @_;

	my $sql = "UPDATE emails SET is_sent = '$status', date_sent = Now() WHERE id = '$id'";

	my $sth = $dbh->prepare($sql);

	$sth->execute();
}


sub Delete {
	my ($dbh, $id) = @_;

	my $sql = "DELETE FROM emails WHERE id = '$id'";

	my $sth = $dbh->prepare($sql);

	$sth->execute();
}


sub Send
{
    my ($subject, $message, $recipient, $from) = @_;
    
    unless ($from)
    {
    	$from = 'meeko@worldofanime.com';
    }

    my $html_message = &HTMLify($message, $subject, $recipient);

    my $msg = MIME::Lite->new(
	From => "$from",
	To => "$recipient",
	Subject => "$subject",
	Type => 'multipart/alternative'
	);

    $msg->attach(
	Type => 'text/plain',
	Data => $message,
	);

    $msg->attach(
	Type => 'text/html',
	Data => $html_message,
	);


    $msg->send_by_smtp('mail.meeko.net');
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
