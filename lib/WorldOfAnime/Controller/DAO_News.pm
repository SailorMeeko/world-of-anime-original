package WorldOfAnime::Controller::DAO_News;
use Moose;
use HTML::Restrict;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }


sub SubmitArticle :Local :Args(0) {
    my ( $c ) = @_;

    my $User = WorldOfAnime::Controller::DAO_Users::GetUserByID( $c, WorldOfAnime::Controller::Helpers::Users::GetUserID($c) );
    my $UserID = $User->id;
 
    my $image_id = 14;  # Default 'no image' image

    # If they uploaded a new image, upload it and set it to the new image_id
    
    if ($c->req->params->{article_image}) {
        my $upload   = $c->req->upload('article_image');
        my $filedir  = $c->config->{uploadfiledir};
        my $justfilename = $upload->filename;
        my $dir = 'news';
        
        $image_id = WorldOfAnime::Controller::DAO_Images::upload_image( $c, $upload, $justfilename, $dir);
    }
    
    
    my $Article = $c->model('DB::NewsArticles')->create({
        title => $c->req->params->{article_title},
        article => $c->req->params->{article},
        pretty_url => $c->model('Formatter')->prettify( $c->req->params->{article_title} ),
        source_url => $c->req->params->{source_url},
        source_name => $c->req->params->{source_name},
        status => 0,
        posted_by => $UserID,
        image_id => $image_id,
        modify_date => undef,
        create_date => undef,
    });
    
    my $article_id = $Article->id;
    
    # Send me an e-mail
    
    my $subject = "New News Article Submitted.";
    my $username = $User->username;
    
    my $body = <<EndOfBody;
$username has submitted a new news article.

Moderate it at http://www.worldofanime.com/moderate/article/$article_id
EndOfBody
    
    WorldOfAnime::Controller::DAO_Email::SendEmail($c, 'meeko@worldofanime.com', 1, $body, $subject);    

    return $article_id;
}


sub GetWaitingArticles :Local :Args(0) {
    my ( $c ) = @_;
    
    my $WaitingArticles = $c->model("DB::NewsArticles")->search( { status => 0 });
    
    return $WaitingArticles;
}


sub FetchRecentArticles :Local :Args(0) {
    my ( $c, $page ) = @_;
    
    my $Articles = $c->model("DB::NewsArticles")->search( {
        status => 1,
    }, {
        page => "$page",        
        rows => 10,
        order_by => 'create_date DESC',
       });
    
    return $Articles;
}


sub GetNewsArticleCacheable :Local :Args(1) {
    my ( $c, $id ) = @_;
    
    my %article;
    my $article_ref;
    
    my $cid = "worldofanime:news_article:$id";
    $article_ref = $c->cache->get($cid);
    
    unless ($article_ref) {
	my $Article  = $c->model('DB::NewsArticles')->find({ id => $id });
	
	if (defined($Article)) {
            
            my $hr = HTML::Restrict->new();

	    $article{'id'}            = $Article->id;
	    $article{'title'}         = $Article->title;
            $article{'pretty_url'}    = $Article->pretty_url;
	    $article{'article'}       = $Article->article;
            $article{'article_clean'} = $hr->process($article{'article'});
            $article{'teaser'}        = $Article->teaser;
            $article{'source_url'}    = $Article->source_url;
            $article{'source_name'}   = $Article->source_name;
            $article{'status'}        = $Article->status;
	    $article{'image_id'}      = $Article->image_id;
            eval { $article{'filedir'}  = $Article->image->filedir; };
            eval { $article{'filename'} = $Article->image->filename; };
            $article{'createdate'}    = $Article->create_date;
            $article{'posted_by'}     = $Article->posted_by;
            $article{'submitted_by'}  = $Article->submitted_by->username;
            
            $article{'article_clean'} =~ s/\"//g;
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%article, 2592000);
	
	
    } else {
	%article = %$article_ref;
    }

    return \%article;    
}


sub GetNewsArticleCommentCacheable :Local :Args(1) {
    my ( $c, $id ) = @_;
    
    my %comment;
    my $comment_ref;
    
    my $cid = "worldofanime:news_article_comment:$id";
    $comment_ref = $c->cache->get($cid);
    
    unless ($comment_ref) {
	my $Comment  = $c->model('DB::NewsArticleComments')->find({ id => $id });
	
	if (defined($Comment)) {

	    $comment{'id'}           = $Comment->id;
	    $comment{'username'}     = $Comment->news_commentor->username;
	    $comment{'user_id'}      = $Comment->news_commentor->id;
            $comment{'filename'}     = $Comment->news_commentor->user_profiles->user_profile_image_id->filename;
	    $comment{'createdate'}   = $Comment->createdate;
            $comment{'comment'}      = $Comment->comment;
            
	}
	
	# Set memcached object for 30 days
	$c->cache->set($cid, \%comment, 2592000);
	
	
    } else {
	%comment = %$comment_ref;
    }

    return \%comment;    
}


sub GetNewsArticleComments {
    my ( $c, $id, $latest, $get_latest_id ) = @_;
    my $Comments;
    
    $Comments = $c->model('DB::NewsArticleComments')->search({
        news_article_id => $id,
        id => { '>' => $latest },
    }, {
        order_by => 'createdate DESC'
       });
    
    if ($get_latest_id) {
        # We need to calculate the latest comment id
        
        my $latest_id = 0;

        my $Latest = $c->model('DB::NewsArticleComments')->search({
        news_article_id => $id,
        id => { '>' => $latest },
    }, {
        rows => 1,
        order_by => 'createdate DESC'
       });

        if ($Latest->count) {
            my $l = $Latest->next;
            $latest_id = $l->id;
        }
        return ($Comments, $latest_id);
    } else {
        return $Comments;
    }
}


sub Search :Path('/news/search') :Args(0) {
    my ( $self, $c ) = @_;
    my $results;
    my $count = 0;

    my $searchString = $c->req->params->{'searchString'};

    my $NewsArticles = $c->model("DB::NewsArticles")->search( {
        -and => [
            -or => [
                teaser => { 'like', "%$searchString%" },
                title => { 'like', "%$searchString%" },
                article => { 'like', "%$searchString%" },
            ],
                status => 1,
        ]            
    },
    {
	order_by => 'create_date DESC',
    });

        if ($NewsArticles) {
            while (my $n = $NewsArticles->next) {
                my $filedir;
                my $filename;
                
                my $id     = $n->id;
                my $title  = $n->title;
                my $teaser = $n->teaser;
                eval { $filedir = $n->image->filedir; };
                eval { $filename = $n->image->filename; };
                my $pretty_title = $c->model('Formatter')->prettify( $title );
                my $createdate    = $n->create_date;
                my $submitted_by  = $n->submitted_by->username;                
	    
                push (@{ $results}, { 'title' => "$title", 'id' => "$id", 'pretty_title' => "$pretty_title", 'filedir' => "$filedir", 'filename' => "$filename", 'teaser' => "$teaser", 'submitted_by' => "$submitted_by", 'createdate' => "$createdate" });
                $count++;
            }
        }

    WorldOfAnime::Controller::DAO_Searches::RecordSearch( $c, 3, $searchString, $count );
    
    if ($results) {
        my $json_text = to_json($results);
        $c->stash->{results} = $json_text;
        $c->forward('View::JSON');
    } else {
        $c->response->body('N');
    }
}


sub CleanArticle {
    my ( $c, $id ) = @_;
    
    $c->cache->remove("worldofanime:news_article:$id");
}


__PACKAGE__->meta->make_immutable;

1;
