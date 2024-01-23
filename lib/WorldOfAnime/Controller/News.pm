package WorldOfAnime::Controller::News;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


sub index :Path('/news') :Args(0) {
    my ( $self, $c ) = @_;

    my $page = $c->req->params->{'page'} || 1;
    
    my $Articles = WorldOfAnime::Controller::DAO_News::FetchRecentArticles( $c, $page );

    my $pager = $Articles->pager();

    $c->stash->{pager}    = $pager;
    $c->stash->{articles} = $Articles;
    $c->stash->{template} = 'news/main_news.tt2';
}


sub newsletter :Path('/newsletter') :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'newsletter.tt2';
}


sub view_article :Path('/news/article') :Args(2) {
    my ( $self, $c, $id, $pretty_url ) = @_;
    my $CommentsHTML;
    my $count = 0;

    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";
    
    my $get_latest_id = 1;
    
    my $Article = WorldOfAnime::Controller::DAO_News::GetNewsArticleCacheable( $c, $id );
    my ($Comments, $latest) = WorldOfAnime::Controller::DAO_News::GetNewsArticleComments( $c, $id, 0, $get_latest_id );
    
    while (my $com = $Comments->next) {
        my $com_id = $com->id;
        my $comment = WorldOfAnime::Controller::DAO_News::GetNewsArticleCommentCacheable( $c, $com_id);
        
        my $filename   = $comment->{'filename'};
        my $user_id    = $comment->{'user_id'};
        my $username   = $comment->{'username'};
        my $createdate = $comment->{'createdate'};
        my $content    = $comment->{'comment'};
        
        my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $user_id );
        my $profile_image_id = $p->profile_image_id;
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;
        
        my $postDate = WorldOfAnime::Controller::Root::PrepareDate($createdate, 1, $tz);
        
        $CommentsHTML .= "<div class=\"comment\">\n";
        $CommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\"></a>\n";
        $CommentsHTML .= "<p class=\"article\">" . $content . "</p>\n";
        $CommentsHTML .= "<br clear=\"all\">\n";
        $CommentsHTML .= "<h2>Submitted by <a href=\"/profile/$username\">$username</a> on $postDate</h2><br />";
        $CommentsHTML .= "</div>\n";
        
        $count++;
    }    
    
    $c->stash->{article} = $Article;
    $c->stash->{comments_html} = $CommentsHTML;
    $c->stash->{num_comments} = $count;
    $c->stash->{latest} = $latest;
    $c->stash->{template} = 'news/main_article.tt2';
}


sub add_news :Path('/news/add_news') :Args(0) {
    my ( $self, $c ) = @_;
    
    $c->stash->{template} = 'news/add_news.tt2';
}


sub submit_news :Path('/news/submit_news') :Args(0) {
    my ( $self, $c ) = @_;
    
    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to submit a news article.");
    my $id = WorldOfAnime::Controller::DAO_News::SubmitArticle( $c );

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $user_id  = $u->{'id'};
    my $username = $u->{'username'};    

    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has submitted a new news article";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 26, $id);
    
    $c->stash->{template} = 'news/submit_news.tt2';    
}



##### AJAX methods

sub add_comment :Path('/news/ajax/add_comment') :Args(1) {
    my ( $self, $c, $id ) = @_;

    WorldOfAnime::Controller::DAO_Users::CheckForUser($c, "You must be logged in to add a comment.");
    
    my $a = WorldOfAnime::Controller::DAO_News::GetNewsArticleCacheable( $c, $id );
    my $title = $a->{'title'};
    my $pretty_url = $a->{'pretty_url'};

    my $u = WorldOfAnime::Controller::DAO_Users::GetCacheableUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $user_id  = $u->{'id'};
    my $username = $u->{'username'};
    
    my $comment = $c->req->params->{comment};
    
    my $nc = $c->model('DB::NewsArticleComments')->create({
        news_article_id => $id,
        user_id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
        comment => $comment,
        modifydate => undef,
        createdate => undef,
    });

    # Remove the cache entry for the number of comments    
    $c->cache->remove("worldofanime:num_news_comments:$id");    
    
    # Create Action
    
    my $ActionDescription = "<a href=\"/profile/" . $username . "\">" . $username . "</a> has commented on the news story ";
    $ActionDescription .= "<a href=\"/news/article/$id/$pretty_url\">$title</a>";
    
    WorldOfAnime::Controller::DAO_Users::AddActionPoints($c, $user_id, $ActionDescription, 28, $id);    
    
    $c->response->body("ok");
}


sub load_comments :Path('/news/ajax/load_comments') :Args(2) {
    my ( $self, $c, $id, $latest ) = @_;
    my $CommentsHTML;
    
    my $tz = ($c->request->cookies->{timezone}) ? $c->request->cookies->{timezone}->value : "";

    my $Comments = WorldOfAnime::Controller::DAO_News::GetNewsArticleComments( $c, $id, $latest );
    
    while (my $com = $Comments->next) {
        my $com_id = $com->id;
        my $comment = WorldOfAnime::Controller::DAO_News::GetNewsArticleCommentCacheable( $c, $com_id);
        
        my $filename   = $comment->{'filename'};
        my $username   = $comment->{'username'};
        my $user_id    = $comment->{'user_id'};
        my $createdate = $comment->{'createdate'};
        my $content    = $comment->{'comment'};
        
        my $p = $c->model('Users::UserProfile');
        $p->get_profile_image( $c, $user_id );
        my $profile_image_id = $p->profile_image_id;
        
        my $i = $c->model('Images::Image');
        $i->build($c, $profile_image_id);
        my $profile_image_url = $i->thumb_url;        
        
        my $postDate = WorldOfAnime::Controller::Root::PrepareDate($createdate, 1, $tz);        
        
        $CommentsHTML .= "<div class=\"comment\">\n";
        $CommentsHTML .= "<a href=\"/profile/$username\"><img src=\"$profile_image_url\"></a>\n";
        $CommentsHTML .= "<p class=\"article\">" . $content . "</p>\n";
        $CommentsHTML .= "<br clear=\"all\">\n";
        $CommentsHTML .= "<h2>Submitted by <a href=\"/profile/$username\">$username</a> on $postDate</h2><br />";
        $CommentsHTML .= "</div>\n";
    }
    
    $c->response->body($CommentsHTML);
}



__PACKAGE__->meta->make_immutable;

1;
