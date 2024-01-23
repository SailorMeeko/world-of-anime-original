package WorldOfAnime::Controller::Moderate;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


sub test :Path('/moderate/test') :Args(0) {
    my ( $self, $c ) = @_;
    my $short;
    
    my $long_url = "http://www.worldofanime.com/";
    
    my $url = $c->model('URL');
    $url->url('http://www.blah.com');
    $short = $url->shorten;
    
    $c->stash->{url} = $long_url;
    $c->stash->{short} = $short;
    $c->stash->{template} = 'moderate/test.tt2';
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::IsModerator( $c );
    
    my $WaitingArticles = WorldOfAnime::Controller::DAO_News::GetWaitingArticles( $c );
    my $WaitingPolls    = $c->model("DB::PollQuestions")->search( { status => 0 });

    if ($c->flash->{tweet}) {
        $c->stash->{tweet} = $c->flash->{tweet};
    }
    
    $c->stash->{waiting_articles} = $WaitingArticles;
    $c->stash->{waiting_polls}    = $WaitingPolls;
    $c->stash->{template} = 'moderate/main_moderate.tt2';
}


sub moderate_news :Path('/moderate/news') :Args(0) {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::IsModerator( $c );
    
    my $WaitingArticles = WorldOfAnime::Controller::DAO_News::GetWaitingArticles( $c );

    $c->stash->{waiting_articles} = $WaitingArticles;
    $c->stash->{template} = 'moderate/moderate_news.tt2';    
}


sub moderate_article :Path('/moderate/article') :Args(1) {
    my ( $self, $c, $article ) = @_;

    WorldOfAnime::Controller::DAO_Users::IsModerator( $c );
    
    my $Article = WorldOfAnime::Controller::DAO_News::GetNewsArticleCacheable( $c, $article );

    $c->stash->{a} = $Article;
    $c->stash->{template} = 'moderate/moderate_article.tt2';        
}


sub modify_news :Path('/moderate/news/modify') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::IsModerator( $c );
    
    my $Article = $c->model("DB::NewsArticles")->find({ id => $c->req->params->{article_id} });
    my $image_id = $Article->image_id;
    
    my $article_id = $c->req->params->{article_id};
    my $title      = $c->req->params->{article_title};
    my $pretty_url = $c->req->params->{pretty_url};
    my $source_url = $c->req->params->{source_url};
    my $source_name = $c->req->params->{source_name};    
    my $teaser     = $c->req->params->{teaser};
    my $article    = $c->req->params->{article};
    my $status     = $c->req->params->{status};
    
    my $full_url = "http://www.worldofanime.com/news/article/$article_id/$pretty_url";
    
    my $url = $c->model('URL');
    $url->url($full_url);
    my $short_url = $url->shorten;
    
    # If they uploaded a new image, upload it and set it to the new image_id
    
    if ($c->req->params->{article_image}) {
        my $upload   = $c->req->upload('article_image');
        my $filedir  = $c->config->{uploadfiledir};
        my $justfilename = $upload->filename;
        my $dir = 'news';
        
        $image_id = WorldOfAnime::Controller::DAO_Images::upload_image( $c, $upload, $justfilename, $dir);
    }
    
    
    $Article->update({
        title       => $title,
        teaser      => $teaser,
        article     => $article,
        short_url   => $short_url,
        pretty_url  => $pretty_url,
        source_url  => $source_url,
        source_name => $source_name,
        status      => $status,
        image_id    => $image_id,
    });
    
    WorldOfAnime::Controller::DAO_News::CleanArticle( $c, $article_id );
    
    # If the status changed from 0 to 1 (initial approval), give them their points

    my $original_status = $c->req->params->{original_status};
    
    if ( ($original_status == 0) && ($status == 1) ) {
        
        my $posted_by = $c->req->params->{posted_by};
        my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, $posted_by);
        my $username = $u->{'username'};    

        my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a>'s news article ";
        $ActionDescription .= "<a href=\"/news/article/$article_id/$pretty_url\">$title</a> has been posted";
        
    
        WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $posted_by, $ActionDescription, 27, $article_id);
        
        my $tweet = "$title - $short_url #anime";
        $c->flash->{tweet} = $tweet;        
    }
    
    $c->response->redirect('/moderate');
}


sub moderate_polls :Path('/moderate/polls') :Args(0) {
    my ( $self, $c ) = @_;

    WorldOfAnime::Controller::DAO_Users::IsModerator( $c );
    
    my $WaitingPolls    = $c->model("DB::PollQuestions")->search( { status => 0 });

    $c->stash->{waiting_polls} = $WaitingPolls;
    $c->stash->{template} = 'moderate/moderate_polls.tt2';    
}


sub moderate_poll :Path('/moderate/poll') :Args(1) {
    my ( $self, $c, $id ) = @_;

    WorldOfAnime::Controller::DAO_Users::IsModerator( $c );
    
    my $p = $c->model('Polls::Poll');
    $p->build( $c, $id );
    $p->build_choices( $c );

    $c->stash->{poll} = $p;
    $c->stash->{template} = 'moderate/specific_poll.tt2';
}


__PACKAGE__->meta->make_immutable;

1;
