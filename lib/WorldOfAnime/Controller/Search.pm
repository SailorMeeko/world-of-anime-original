package WorldOfAnime::Controller::Search;

use strict;
use warnings;
use parent 'Catalyst::Controller';


sub search :Path('/search') Args(0) {
    my ( $self, $c ) = @_;


		if ($c->req->params->{'clear'}) {
			
			undef $c->session->{search};
			undef $c->session->{about_me};
			undef $c->session->{username};
			undef $c->session->{realname};
			undef $c->session->{gender};
			undef $c->session->{favorite_anime};
			undef $c->session->{favorite_movies};
			
			$c->stash->{template} = 'search/setup.tt2';			
		}


		if ( ($c->req->params->{'search'}) || ($c->session->{search}) ) {

	    my $page = $c->req->params->{'page'} || 1;
	    
	    my $gender   = $c->req->params->{'gender'}   || $c->session->{gender};
	    my $realname = $c->req->params->{'realname'} || $c->session->{realname};
	    my $about_me = $c->req->params->{'about_me'} || $c->session->{about_me};
	    my $username = $c->req->params->{'username'} || $c->session->{username};
			my $favorite_anime = $c->req->params->{'favorite_anime'} || $c->session->{favorite_anime};
			my $favorite_movies = $c->req->params->{'favorite_movies'} || $c->session->{favorite_movies};
			
			my $search_favorite_anime = lc($favorite_anime);
			my $search_favorite_movies = lc($favorite_movies);


  	  my $Members = $c->model("DB::Users")->search({
    	    status => 1,
    	    username => { like => "%$username%" }, 
    	    'user_profiles.name'     => { like => "%$realname%" },
    	    about_me => { like => "%$about_me%" },
    	    gender   => { like => "%$gender%" },
    	  },{
    	  	join      => [ 'user_profiles' ],
    	  	distinct => 1,
    	  	order_by => 'me.confirmdate DESC',
    	  });
    	  
    	  my $AnimeMembers;
    	  if ($favorite_anime) {
    	  	$AnimeMembers = $Members->search({
    	  	'lcase(favorite_to_anime_title.name)' => { like => "%$search_favorite_anime%" },
    	  },{ 
    	  	join => [ { 'user_to_favorite_anime' => 'favorite_to_anime_title' } ],
    	  });
    	} else {
    			$AnimeMembers = $Members;
    		}
    	  
    	  my $MovieMembers;
    	  if ($favorite_movies) {
    	  	$MovieMembers = $AnimeMembers->search({
    	  	'lcase(favorite_to_movie_title.name)' => { like => "%$search_favorite_movies%" },
    	  },{ 
    	  	join => [  { 'user_to_favorite_movie' => 'favorite_to_movie_title' } ],
    	  });
    	} else {
    			$MovieMembers = $AnimeMembers;
    		}
    	  
    	  my $ResultsCount = $MovieMembers;
    	  
    	  # Now paginate them
    	  
    	  my $FinalMembers = $MovieMembers->search({ }, {
        	page      => "$page",
	        rows      => 16,        
  	      });    	  	
    	  

			# Now, record this search (only if we are on the first page)

    	my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);			
    	
			if ($page == 1) {
				my $Search = $c->model("DB::Searches")->create({
					searcher_id        => $viewer_id,
					searched_username  => $username,
					searched_real_name => $realname,
					searched_gender    => $gender,
					searched_about_me  => $about_me,
					searched_anime     => $favorite_anime,
					searched_movies    => $favorite_movies,
					results            => $ResultsCount,		
					search_date      => undef,			
			});
		}


    	my $pager = $FinalMembers->pager();

    	$c->stash->{pager}    = $pager;
    
    	$c->stash->{Members} = $FinalMembers;    
			$c->session->{gender} = $gender;

			$gender =~ s/^m$/Male/;
			$gender =~ s/^f$/Female/;
			unless ($gender) { $gender = "Any"; }

			$c->session->{search} = 1;
			$c->session->{about_me} = $about_me;
			$c->session->{username} = $username;
			$c->session->{realname} = $realname;
			$c->session->{favorite_anime}  = $favorite_anime;
			$c->session->{favorite_movies} = $favorite_movies;

			$c->stash->{gender}   = $gender;
			$c->stash->{about_me} = $about_me;
			$c->stash->{username} = $username;
			$c->stash->{realname} = $realname;			    
			$c->stash->{favorite_anime}  = $favorite_anime;
			$c->stash->{favorite_movies} = $favorite_movies;
    	$c->stash->{template} = 'search/display_users.tt2';
    } else {
    	
    	$c->stash->{template} = 'search/setup.tt2';
    }
}




1;
