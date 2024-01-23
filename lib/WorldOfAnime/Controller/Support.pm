package WorldOfAnime::Controller::Support;

use strict;
use parent 'Catalyst::Controller';


sub index :Path('/support') {
    my ( $self, $c ) = @_;
    
   $c->stash->{images_approved} = 1;    
   $c->stash->{template} = 'support/main_support.tt2';
}



1;