package WorldOfAnime::View::Plain;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        WorldOfAnime->path_to( 'root', 'src' ),
        WorldOfAnime->path_to( 'root', 'lib' )
    ],
    ERROR        => 'error.tt2',
});


1;

