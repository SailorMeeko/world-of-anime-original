package WorldOfAnime::Controller::Polls;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff    

    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'polls/main_polls.tt2';
}


sub polls_branch1 :Path('/polls') :Args(1) {
    my ( $self, $c, $action ) = @_;
    
    if ($action eq "suggest_new_poll") {
        $c->forward('suggest_new_poll');
    }
}


sub suggest_new_poll :Local {
    my ( $self, $c ) = @_;
    
    # Check to make sure they are logged in, or show error
    
    unless ($c->user_exists() ) {
        $c->stash->{error_message} = "You must be logged in to suggest a new poll.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }
    
    # Who is suggesting this?
    my $user_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $p = $c->model('Users::UserProfile');
    $p->build( $c, $user_id );    

    
    my $username = $p->username;

    my $question = $c->req->params->{'question'};
    my $choices  = $c->req->params->{'choices'};
    
    # If they haven't entered a question or some choices, send back
    
    unless ($question && $choices) {
        $c->stash->{error_message} = "You must enter a poll and some choices.";
        $c->stash->{question}  = $question;
        $c->stash->{choices}   = $choices;
        $c->stash->{template}      = 'error_page.tt2';
        
        my $current_uri = $c->req->uri;
        $current_uri =~ s/\?(.*)//; # To remove the pager stuff    

        $c->stash->{current_uri} = $current_uri;
        $c->detach();        
    }
    
    # Create the poll
    
    my $Poll = $c->model('DB::PollQuestions')->create({
	group_id => 0,  # This is for main, not a group
        created_by => $user_id,
        poll => $question,
        status => 0,  # Start as suggested
        modifydate => undef,
        createdate => undef,
    });
    
    my $poll_id = $Poll->id;
    
    # Create the choices
    
    my @choices = split(/\n/, $choices);
    
    foreach my $choice (@choices) {
        my $Choice = $c->model('DB::PollChoices')->create({
            poll_id => $poll_id,
            choice => $choice,
            votes => 0,
            status => 1,  # Start as active
            modifydate => undef,
            createdate => undef,
        });
    }


    # Go back to main questions
    
   $c->response->redirect("/polls");
}


__PACKAGE__->meta->make_immutable;

1;
