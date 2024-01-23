package WorldOfAnime::Controller::DAO_Games;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


sub TranslateCategoryName :Local {
    my ( $c, $name ) = @_;
    my $CategoryID;
    
    unless ($CategoryID) {
        
        my $Category = $c->model('DB::GameCategories')->find({
            pretty_url => $name,
        });
        
        if ($Category) {
            $CategoryID = $Category->id;
        }
        
    }
    
    return $CategoryID;
}


sub GetCategoryByName :Local {
    my ( $c, $name ) = @_;
    my $Category;
    
    unless ($Category) {
        
        $Category = $c->model('DB::GameCategories')->find({
            pretty_url => $name,
        });
    }
    
    return $Category;
}


sub FetchGameByURL :Local {
    my ( $c, $pretty_url ) = @_;
    my $Game;
    
    unless ($Game) {
        
        $Game = $c->model('DB::Games')->find(
        { pretty_url => $pretty_url,
        });
    }
    
    return $Game;
}


sub EmptyGameCategories :Local {
    my ( $c, $game_id ) = @_;
    
    my $GameCategories = $c->model('DB::GamesInCategories')->search({
        game_id => $game_id,
    });
    
    $GameCategories->delete;
}


sub AssignGameCategories :Local {
    my ( $c, $game_id ) = @_;
    my @categories = ();
    
    my $categories = $c->req->params->{'categories'};
    
    if ($categories) {
        if ($categories =~ m/^\d+$/) {
            push (@categories, $categories);
        } else {
            foreach my $cat (@{ $categories}) {
                push (@categories, $cat);
            }
        }
    }    
    
    foreach my $cat (@categories) {
        my $Category = $c->model('DB::GamesInCategories')->create({
            game_id     => $game_id,
            category_id => $cat,
            modifydate  => undef,
            createdate  => undef,
        });
    }
    
}


sub RecordPlay :Local {
    my ( $c, $Game ) = @_;
    
    if ($Game) {
        $Game->update({
            play_count => $Game->play_count + 1,
        });
        
        my $Play = $c->model('GamePlays')->create({
            game_id => $Game->id,
            user_id => WorldOfAnime::Controller::Helpers::Users::GetUserID($c),
            modifydate => undef,
            createdate => undef,
        })
    }
}


__PACKAGE__->meta->make_immutable;

1;
