package WorldOfAnime::Controller::Helpers::External;

use parent 'Catalyst::Controller';
use LWP::UserAgent;
use JSON;

sub IsKnownSpammer :Local {
    my ( $c, $ip_address ) = @_;
    my $IsSpammer = 0;  # Assume no
    
    # Adjust this as necessary
    my $confidence_threshold = 1;
    
    # For testing - this is a known spammer's IP address
    # $ip_address = '198.40.54.130';
    
    my $ua = LWP::UserAgent->new;
    my $url = "http://www.stopforumspam.com/api?ip=$ip_address&f=json";
    
    my $response = $ua->post($url);

    if ( $response->is_success ) {
        my $obj = eval { decode_json $response->content } || {};
        
        if ( ($obj->{ip}->{appears}) && ($obj->{ip}->{confidence} > $confidence_threshold) ) {

            $IsSpammer = 1;
            
            # Log their info
            
            $c->model("DB::StopForumSpamLog")->create({
                ip_address => $ip_address,
                frequency => $obj->{ip}->{frequency},
                confidence => $obj->{ip}->{confidence},
                createdate => undef,
            });
        }
    }    
    
    return $IsSpammer;
}

1;