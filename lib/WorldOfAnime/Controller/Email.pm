package WorldOfAnime::Controller::Email;

use strict;
use warnings;
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';


sub setup_optout :Path('/optout') :Args(1) {
    my ( $self, $c, $email ) = @_;
    
    $c->stash->{optout} = $email;
    $c->stash->{template} = 'email/setup_optout.tt2';
}


sub optout :Path('/optout') :Args(0) {
    my ( $self, $c ) = @_;
    
    my $email = $c->req->params->{'email'};
    
    if ($email) {
        WorldOfAnime::Controller::DAO_Email::OptOut($c, $email);
    }
    
    $c->stash->{template} = 'email/optout.tt2';
}


1;
