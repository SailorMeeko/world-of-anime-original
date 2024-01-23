package WorldOfAnime::Controller::Helpers::Images;
use String::Random qw(random_string);

use parent 'Catalyst::Controller';

sub GenerateImageFilename :Local {
    my ( $filename ) = @_;
    
    if ( length($filename) > 248 ) {
        $filename = substr $filename, -248;
    }
    
    return random_string("cccccccc") . "_" . $filename;
}

1;