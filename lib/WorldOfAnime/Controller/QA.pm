package WorldOfAnime::Controller::QA;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use List::MoreUtils qw(uniq);

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';


sub index :Path('/answers') {
    my ( $self, $c ) = @_;
    my @image_ids;
    my $AnswersHTML;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $current_uri = $c->req->uri;
    $current_uri =~ s/\?(.*)//; # To remove the pager stuff

    my $cpage = $c->req->params->{'cpage'} || 1;    
    
    my $Questions = $c->model('DB::QAQuestions')->search({
	group_id => 0,
    }, {
	page     => "$cpage",
        rows      => 25,
        order_by => 'create_date DESC',
        });
    
    $AnswersHTML .= "<div id=\"posts\">\n";
    
    my $cpager = $Questions->pager();
    
    while (my $question = $Questions->next) {
	
	my $asked_by_user_id = $question->asked_by;
	my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $asked_by_user_id );
	
	# Count answers
	my $answer_count = $question->qa_answers;
	my $answer_text  = $answer_count . " answer";
	unless ($answer_count == 1) { $answer_text .= "s"; }
	
        my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $asked_by_user_id );
        my $profile_image_id = $p->profile_image_id;
	my $height           = $p->profile_image_height;
	my $width            = $p->profile_image_width;
	push (@image_ids, $profile_image_id);
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;	
	
	my $username   = $u->{'username'};

	my $mult    = ($height / 80);

	my $new_height = int( ($height/$mult) / 1.5 );
	my $new_width  = int( ($width/$mult) /1.5);
	my $ask_date = $question->create_date;
	my $displayAskDate = WorldOfAnime::Controller::Root::PrepareDate($ask_date, 1, $tz);
        
	$AnswersHTML .= "<div id=\"qa_box\">\n";
	$AnswersHTML .= "<table border=\"0\">\n";
	$AnswersHTML .= "	<tr>\n";
	$AnswersHTML .= "		<td valign=\"top\" rowspan=\"2\">\n";
	$AnswersHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" height=\"$new_height\" width=\"$new_width\"></a>";
	$AnswersHTML .= "		</td>\n";
	$AnswersHTML .= "		<td valign=\"top\" width=\"360\">\n";
	$AnswersHTML .= "			<span class=\"qa_subject\"><a href=\"/answers/" . $question->id . "\">" . $c->model('Formatter')->clean_html($question->subject) . "</a></span>\n";
	$AnswersHTML .= "		</td>\n";
	$AnswersHTML .= "	</tr>\n";
	$AnswersHTML .= "	<tr>\n";
	$AnswersHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Asked by $username on $displayAskDate | $answer_text</span></td>\n";
	$AnswersHTML .= "	</tr>\n";
	$AnswersHTML .= "</table>\n";
	$AnswersHTML .= "</div>\n\n";
	$AnswersHTML .= "<p />\n";        
    }
    
    $AnswersHTML .= "</div>\n";

    my $jquery = <<EndOfHTML;
<script type="text/javascript">
    \$(function() {    
	\$('.removable_button').submit(function() {
            \$('.removable').remove();
	});
    });
</script>
EndOfHTML

    @image_ids = uniq(@image_ids);

    $c->stash->{images_approved} = WorldOfAnime::Controller::DAO_Images::IsImagesApproved( $c, @image_ids ) &&
                          WorldOfAnime::Controller::DAO_Images::IsExternalLinksApprovedPreRender( $c, $AnswersHTML );
    $c->stash->{cpager}    = $cpager;
    $c->stash->{jquery}       = $jquery;
    $c->stash->{AnswersHTML} = $AnswersHTML;
    $c->stash->{current_uri} = $current_uri;
    $c->stash->{template} = 'answers/main.tt2';
}


sub qa_branch1 :Path('/answers') :Args(1) {
    my ( $self, $c, $action ) = @_;
    
    if ($action eq "add_new_question") {
        $c->forward('add_new_question');
    }
    
    if ($action eq "add_new_answer") {
	$c->forward('add_new_answer');
    }

    if ($action =~ /(\d+)/) {
	$c->detach('display_question');
    }
    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();    
}

sub qa_branch2 :Path('/answers') :Args(2) {
    my ( $self, $c, $id, $action ) = @_;
    
    if ($action eq "subscribe") {
	$c->forward('subscribe_question');
    }

    if ($action eq "unsubscribe") {
	$c->forward('unsubscribe_question');
    }
    
    # If nothing, forward somewhere (so they don't get the "not found" page)
    
    $c->stash->{error_message} = "I don't know what you're trying to do.";
    $c->stash->{template}      = 'error_page.tt2';
    $c->detach();    
}


sub add_new_question :Local {
    my ( $self, $c ) = @_;
    
    # Check to make sure they are logged in, or show error
    
    unless ($c->user_exists() ) {
        $c->stash->{error_message} = "You must be logged in to add a new question.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }
    
    # Who is asking this?
		
    my $Asker = $c->model("DB::Users")->find({
    	id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
    });
    
    my $username = $Asker->username;

    my $subject   = $c->req->params->{'subject'};
    my $question  = $c->req->params->{'question'};
    my $subscribe = $c->req->params->{'subscribe'};
    
    # If they haven't entered a question name or subject, send back
    
    unless ($subject && $question) {
        $c->stash->{error_message} = "You must enter a subject and a question.";
        $c->stash->{subject}    = $subject;
        $c->stash->{question}   = $question;
        $c->stash->{subscribe}  = $subscribe;
        $c->stash->{template}      = 'error_page.tt2';
        
        my $current_uri = $c->req->uri;
        $current_uri =~ s/\?(.*)//; # To remove the pager stuff    

        $c->stash->{current_uri} = $current_uri;
        $c->detach();        
    }
    
    # Create the question
    
    my $Question = $c->model('DB::QAQuestions')->create({
        asked_by => $Asker->id,
	group_id => 0,
        subject  => $subject,
        question => $question,
        modify_date => undef,
        create_date => undef,
    });

    # If they want to subcribe, add them
    
    if ($subscribe) {
        
        my $QAUser = $c->model('DB::QASubscriptions')->create({
            question_id => $Question->id,
            user_id  => $Asker->id,
            modify_date => undef,
            create_date => undef,
        });
    }
    
    # Always subscribe me
    
    my $Sub = $c->model('DB::QASubscriptions')->create({
        question_id => $Question->id,
        user_id => 3,
        modify_date => undef,
        create_date => undef,
    });    
    
    # Add action points
    
    my $ActionDescription = "<a href=\"/profile/" . $Asker->username . "\">" . $Asker->username . "</a> posted a new ";
    $ActionDescription   .= "<a href=\"/answers/" . $Question->id . "\">question</a>";

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $Asker->id,
	action_id => 13,
	action_object => $Question->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });
    
    my $question_id = $Question->id;

    my $Friends = $c->model("DB::UserFriends")->search({
        user_id => $Asker->id,
        status  => 2,
    },{
                select   => [qw/friend_user_id modifydate/],
                distinct => 1,
		order_by => 'modifydate DESC',
    });
    
    while (my $f = $Friends->next) {
	WorldOfAnime::Controller::Notifications::AddNotification($c, $f->friends->id, "<a href=\"/profile/" . $username . "\">" . $username . "</a> has posted a new <a href=\"/answers/$question_id\">question</a> in Anime Anwers.", 9);
    }      
    
    # Go back to main questions
    
   $c->response->redirect("/answers");
}



sub add_new_answer :Local {
    my ( $self, $c ) = @_;
    
    my $id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    # Check to make sure they are logged in, or show error
    
    unless ($c->user_exists() ) {
        $c->stash->{error_message} = "You must be logged in to add a new answer.";
        $c->stash->{template}      = 'error_page.tt2';
        $c->detach();
    }
    
    # Who is answering this?

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $id );
    
    my $username    =  $u->{'username'};
    
    my $question_id = $c->req->params->{'question_id'};
    my $answer      = $c->req->params->{'answer'};

    # Write answer
    
    my $Answer = $c->model('DB::QAAnswers')->create({
	question_id => $question_id,
	answered_by => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
	answer      => $answer,
	modify_date => undef,
	create_date => undef,
    });

    my $subject = $Answer->question->subject;
    my $asker   = $Answer->question->asked_by_user->username;
    my $name    = $asker . "'s";
    
	
    # E-mail whoever is subscribed to this question

    my $Subs = $c->model('DB::QASubscriptions')->search({
	question_id => $question_id,
    });
    
    while (my $s = $Subs->next) {
	# Figure out user in s
	my $User = $s->qa_subscription_user_id;
	
	my $HTMLUsername = $username;
	$HTMLUsername =~ s/ /%20/g;

	# Create e-mail object
	
	my $Body;
	
	$Body .= "http://www.worldofanime.com/profile/$HTMLUsername has posted an answer to the question " . $subject . ".  The answer was:\n";
	$Body .= $answer . "\n\n";
	$Body .= "Read the full question and all answers here - http://www.worldofanime.com/answers/" . $question_id . "\n";
	$Body .= "You can also unsubscribe from this thread from the URL above.";

	WorldOfAnime::Controller::DAO_Email::SendEmail($c, $User->email, 1, $Body, 'New Answer to a Question.');
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $User->id, "<a href=\"/profile/" . $HTMLUsername . "\">" . $username . "</a> has posted a new answer to <a href=\"/profile/$asker\">$name</a> question <a href=\"/answers/$question_id\">$subject</a>.", 14);
    }
    

    my $Answerer = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, $id );    
    
    # Add action points
    
    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> posted a new ";
    $ActionDescription   .= "<a href=\"/answers/" . $question_id . "\">answer</a> to a question";

    my $UserAction = $c->model("DB::UserActions")->create({
	user_id => $id,
	action_id => 14,
	action_object => $Answer->id,
	description => $ActionDescription,
	modify_date => undef,
	create_date => undef,
    });

    # Go back to specific question
    
   $c->response->redirect("/answers/$question_id");
}


sub display_question :Local {
    my ( $self, $c, $id ) = @_;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    my $QuestionHTML;
    my $AnswersHTML;

    my $QA = $c->model('DB::QAQuestions')->search({
	id => $id,
	group_id => 0,
    });
    
    my $question = $QA->first;

    unless ($question) {
	$c->stash->{error_message} = "What?  That doesn't seem like a real question.";
	$c->stash->{template}    = 'error_page.tt2';
	$c->detach();
    }
    
    
    if ($viewer_id) {
	# Someone is logged in - lets see if they are subscribed to this question
	
	my $Sub = $c->model('DB::QASubscriptions')->find({
	    question_id => $id,
	    user_id   => $viewer_id,
	});
	
	if ($Sub) {
	    $c->stash->{IsSub} = 1;
	}
    }
    
    
    $QuestionHTML .= "<div id=\"posts\">\n";
    
    my $DisplayQuestion = $question->question;
    $DisplayQuestion =~ s/\n/<br \/>/g;
    if ($DisplayQuestion =~ /<a href=(.*)>(.*)</) {
	my $link = $2;
	$link = substr $link, 0, 40;
	$link .= "...";
	$DisplayQuestion =~ s/<a href=(.*)>(.*)<(.*)/<a href=$1>$link<$3/;
    }
    
    $DisplayQuestion  = WorldOfAnime::Controller::Root::ResizeComment($DisplayQuestion, 520);

    my $asked_by_user_id = $question->asked_by;
    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $asked_by_user_id );
    
    my $username   = $u->{'username'};
    
    my $p = $c->model('Users::UserProfile');
    $p->get_profile_image( $c, $asked_by_user_id );
    my $profile_image_id = $p->profile_image_id;
    
    my $i = $c->model('Images::Image');
    $i->build($c, $profile_image_id);
    my $profile_image_url = $i->thumb_url;
	
    my $ask_date = $question->create_date;
    my $displayAskDate = WorldOfAnime::Controller::Root::PrepareDate($ask_date, 1, $tz);
        
    $QuestionHTML .= "<div id=\"qa_box\">\n";
    $QuestionHTML .= "<table border=\"0\">\n";
    $QuestionHTML .= "	<tr>\n";
    $QuestionHTML .= "		<td valign=\"top\" rowspan=\"3\">\n";
    $QuestionHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\"></a>";
    $QuestionHTML .= "		</td>\n";
    $QuestionHTML .= "		<td valign=\"top\" width=\"360\">\n";
    $QuestionHTML .= "			<span class=\"qa_subject\">" . $c->model('Formatter')->clean_html($question->subject) . "</span>\n";
    $QuestionHTML .= "                  <span class=\"qa_question\">" . $c->model('Formatter')->clean_html($DisplayQuestion) . "</span>\n";
    $QuestionHTML .= "		</td>\n";
    $QuestionHTML .= "	</tr>\n";
    $QuestionHTML .= "	<tr>\n";
    $QuestionHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Asked by $username on $displayAskDate</span></td>\n";
    $QuestionHTML .= "	</tr>\n";
    if ($viewer_id) {
	$QuestionHTML .= "	<tr>\n";
        $QuestionHTML .= "		<td colspan=\"2\" valign=\"bottom\">";
	$QuestionHTML .= "		<div id=\"setup_answer\"><a href=\"#\" class=\"reply_button\" onclick=\"javascript:\$('#answer_question').show();\$('#answer_box #answer_entry').focus();\$('#setup_answer').remove();return false\">Answer Question</a></div>";
	$QuestionHTML .= "<div id=\"answer_question\" style=\"display: none;\" class=\"answer_box\">";
        $QuestionHTML .= "<h2>Answer Question</h2>\n";
	$QuestionHTML .= "<form id=\"answer_box\" class=\"removable_button\" action=\"/answers/add_new_answer\" method=\"post\">";
        $QuestionHTML .= "<input type=\"hidden\" name=\"question_id\" value=\"" . $question->id . "\">\n";
	$QuestionHTML .= "<textarea id=\"answer_entry\" rows=\"8\" cols=\"54\" name=\"answer\"></textarea>\n<br clear=\"all\">\n";
        $QuestionHTML .= "<input type=\"submit\" value=\"Answer\" style=\"float: right; margin-right: 25px; margin-top: 5px; margin-bottom: 5px;\" class=\"removable\">\n<br clear=\"all\">\n";
	$QuestionHTML .= "</form>\n";
        $QuestionHTML .= "</div>\n";
        $QuestionHTML .= "</td>\n";
        $QuestionHTML .= "	</tr>\n";
    }
    $QuestionHTML .= "</table>\n";
    $QuestionHTML .= "</div>\n\n";
    $QuestionHTML .= "<p />\n";
    
    $QuestionHTML .= "</div>\n";


    # Get answers to question
    
    $AnswersHTML .= "<div id=\"posts\">\n";
    
    my $Answers = $c->model('DB::QAAnswers')->search({
	question_id => $id,
    });
    
    while (my $answer = $Answers->next) {
	my $DisplayAnswer = $answer->answer;
	$DisplayAnswer  = WorldOfAnime::Controller::Root::ResizeComment($DisplayAnswer, 540);
	
	my $answered_by_user_id = $answer->answered_by;
        my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $answered_by_user_id );	
	
	my $username   = $u->{'username'};
	
	my $p = $c->model('Users::UserProfile');
	$p->get_profile_image( $c, $answered_by_user_id );
	my $profile_image_id = $p->profile_image_id;
	my $height = $p->profile_image_height;
	my $width  = $p->profile_image_width;
	
	my $i = $c->model('Images::Image');
	$i->build($c, $profile_image_id);
	my $profile_image_url = $i->thumb_url;	

	my $mult    = ($height / 80);

	my $new_height = int( ($height/$mult) / 1.5 );
	my $new_width  = int( ($width/$mult) /1.5);
	
        my $answer_date = $answer->create_date;
	my $displayAnswerDate = WorldOfAnime::Controller::Root::PrepareDate($answer_date, 1, $tz);
	
	$DisplayAnswer =~ s/\n/<br \/>/g;
        
        $AnswersHTML .= "<div id=\"qa_box\">\n";
        $AnswersHTML .= "<table border=\"0\">\n";
        $AnswersHTML .= "	<tr>\n";
        $AnswersHTML .= "		<td valign=\"top\" rowspan=\"3\">\n";
        $AnswersHTML .= "			<a href=\"/profile/$username\"><img src=\"$profile_image_url\" border=\"0\" height=\"$new_height\" width=\"$new_width\"></a>";
        $AnswersHTML .= "		</td>\n";
        $AnswersHTML .= "		<td valign=\"top\" width=\"360\">\n";
        $AnswersHTML .= "                  <span class=\"qa_question\">" . $c->model('Formatter')->clean_html($DisplayAnswer) . "</span>\n";
        $AnswersHTML .= "		</td>\n";
        $AnswersHTML .= "	</tr>\n";
        $AnswersHTML .= "	<tr>\n";
        $AnswersHTML .= "		<td colspan=\"2\" valign=\"bottom\"><span class=\"top_user_profile_date\">Answered by $username on $displayAnswerDate</span></td>\n";
        $AnswersHTML .= "	</tr>\n";
        $AnswersHTML .= "</table>\n";
        $AnswersHTML .= "</div>\n\n";
        $AnswersHTML .= "<p />\n";
    }
    
    $AnswersHTML .= "</div>\n";

    $c->stash->{QuestionID}   = $id;
    $c->stash->{QuestionHTML} = $QuestionHTML;
    $c->stash->{AnswersHTML}  = $AnswersHTML;
    #$c->stash->{Subject}      = $question->subject;
    $c->stash->{Question}     = $question;
    $c->stash->{template} = 'answers/question.tt2';
}


sub subscribe_question :Local {
    my ( $self, $c, $id, $action ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Get this question
    
    my $QA = $c->model('DB::QAQuestions')->find({
        id      => $id,
    });
    
    my $user_id = $QA->asked_by_user->id;
    my $subject = $QA->subject;
    
    
    # Get subscriber
    
    my $User = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $User->username;
    
    # Add subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::QASubscriptions')->create({
	    question_id => $id,
	    user_id => $viewer_id,
	    modify_date => undef,
	    create_date => undef,
        });
	
	WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has subscribed to your question titled <a href=\"/answers/$id\">$subject</a>.", 8);
    }
    
    $c->response->redirect("/answers/$id");    
}


sub unsubscribe_question :Local {
    my ( $self, $c, $id, $action ) = @_;

    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

    # Get this question
    
    my $QA = $c->model('DB::QAQuestions')->find({
        id      => $id,
    });
    
    my $user_id = $QA->asked_by_user->id;
    my $subject = $QA->subject;
    
    
    # Get subscriber
    
    my $User = $c->model("DB::Users")->find({
        id => $viewer_id,
    });
    
    my $FromUsername = $User->username;
    
    # Remove subscription
    
    if ($viewer_id) {
	my $Sub = $c->model('DB::QASubscriptions')->find({
	    question_id => $id,
	    user_id => $viewer_id,
        });
	
	if ($Sub) {
	    $Sub->delete;
	    
	    WorldOfAnime::Controller::Notifications::AddNotification($c, $user_id, "<a href=\"/profile/" . $FromUsername . "\">" . $FromUsername . "</a> has unsubscribed from your question titled <a href=\"/answers/$id\">$subject</a>.", 13);
	}
    }
    
    $c->response->redirect("/answers/$id");    
}




1;
