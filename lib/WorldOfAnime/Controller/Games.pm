package WorldOfAnime::Controller::Games;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub games :Path('/games') :Args(0) {
    my ( $self, $c ) = @_;
 
    my $GameCategories = $c->model('DB::GameCategories')->search({ }, order_by => 'Precedence ASC' );
    
    # Most recent games
    my $RecentGames = $c->model('DB::Games')->search({ }, { order_by => 'createdate DESC', rows => 12, });

    $c->stash->{GameCategories} = $GameCategories;
    $c->stash->{RecentGames}    = $RecentGames;
    $c->stash->{template} = 'games/main_games.tt2';
}


sub play_game :Path('/games') :Args(1) {
    my ( $self, $c, $pretty_url ) = @_;

    # Only a logged in user can play
    if ( $c->user_exists() ) {

        my $Game = WorldOfAnime::Controller::DAO_Games::FetchGameByURL( $c, $pretty_url );
    
        if ($Game) {
            # Record this play
        
            WorldOfAnime::Controller::DAO_Games::RecordPlay( $c, $Game );
        }

        $c->stash->{Game} = $Game;
    }
    
    
    $c->stash->{template} = 'games/game.tt2';    
}

sub game_categories :Path('/games/category') :Args(1) {
    my ( $self, $c, $pretty_url ) = @_;
    
    my $Category = WorldOfAnime::Controller::DAO_Games::GetCategoryByName( $c, $pretty_url );
    
    if ($Category) {
        my $Games = $c->model('DB::GamesInCategories')->search({
            category_id => $Category->id,
        },{
           order_by => 'createdate DESC'
          });
    
        $c->stash->{Games} = $Games;
        $c->stash->{Category} = $Category;
    }
    
    $c->stash->{template} = 'games/category.tt2';
}

__PACKAGE__->meta->make_immutable;

1;
