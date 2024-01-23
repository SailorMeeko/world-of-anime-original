#!/usr/bin/perl

BEGIN {
        push @INC, "/var/www/crons";
}

use DBConnector;
use JSON;
use MIME::Lite;

my %databases = ( "worldofanime", "" );


foreach my $k (keys %databases) {

	my $DBCon = DBConnector->new();
	my $dbh   = $DBCon->GetConn($k, $databases{$k});

	# Get all waiting e-mails to stage

	my $Emails = &GetEmails($dbh);

	foreach my $e (@{ $Emails} ) {
		my $subject = $e->{subject};
		my $body    = $e->{body};
		my $from    = $e->{from_email};
		my $to_email_json = $e->{to_email};
		my $to_email;
		
		if ($to_email_json) { $to_email = from_json( $to_email_json ); }
		
		foreach my $e (@{ $to_email}) {
		
			&Create($dbh, $subject, $body, $e->{email}, $from);
		}
	}

}



sub GetEmails {
	my ($dbh) = @_;
	my $all;

	my $sql = "SELECT * FROM staging_emails";

	my $sth = $dbh->prepare($sql);

	$sth->execute();

	while (my $ref = $sth->fetchrow_hashref) {
		push (@{ $all}, $ref);
		
		&Delete($dbh, $ref->{id});
	}

	return $all;
}


sub Delete {
	my ($dbh, $id) = @_;

	my $sql = "DELETE FROM staging_emails WHERE id = '$id'";

	my $sth = $dbh->prepare($sql);

	$sth->execute();
}


sub Create
{
    my ($dbh, $subject, $message, $recipient, $from) = @_;
    
    unless ($from)
    {
    	$from = 'meeko@worldofanime.com';
    }
    
    my $sql = "INSERT INTO emails (from_email, to_email, subject, body, createdate, modifydate) VALUES (?, ?, ?, ?, NULL, NULL)";
    
    my $sth = $dbh->prepare($sql);
    
    $sth->bind_param(1, $from);
    $sth->bind_param(2, $recipient);
    $sth->bind_param(3, $subject);
    $sth->bind_param(4, $message);
    
    $sth->execute();

    return 1;
}


1;
