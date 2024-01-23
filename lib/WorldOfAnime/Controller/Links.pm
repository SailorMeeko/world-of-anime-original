package WorldOfAnime::Controller::Links;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched WorldOfAnime::Controller::Links in Links.');
}


sub view_links :Path('/links') :Args(0) {
    my ( $self, $c ) = @_;

    # Root level categories
    
    my $pid = 0;
    
    my $Categories = $c->model('DB::LinksCategories')->search({
        parent_category_id => 1,
    });
    
    my $CategoriesHTML;
    
    while (my $cat = $Categories->next) {
        $CategoriesHTML .= "<div id=\"category_link_box\">\n";
        $CategoriesHTML .= "<a href=\"/links/" . $cat->id . "\">" . $cat->name . "</a><br />\n";
        $CategoriesHTML .= "<span class=\"info_text\">" . $cat->description . "</span>\n";
        $CategoriesHTML .= "</div>\n";
    }


    $c->stash->{cat_word} = 'Categories';
    $c->stash->{categories_html} = $CategoriesHTML;
    $c->stash->{links_html} = "No Links Here";
    $c->stash->{template} = 'links/view_links.tt2';
}


sub view_links_sub :Path('/links') :Args(1) {
    my ( $self, $c, $cat ) = @_;

    # Get this category name

    # Get all link categories and subcategories

    my $Category = $c->model('DB::LinksCategories')->find({
	id => $cat,
    });
    
    my $cat_name = $Category->name;
    
    until ($Category->parent_category_id == 1) {
	$Category = $c->model('DB::LinksCategories')->find({
	    id => $Category->parent_category_id,
	});
	
	$cat_name = "<a href=\"/links/" . $Category->id . "\">" . $Category->name . "</a> -> " . $cat_name;
    }    




    my $Categories = $c->model('DB::LinksCategories')->search({
        parent_category_id => $cat,
    });
    
    my $CategoriesHTML;
    
    while (my $cat = $Categories->next) {
        $CategoriesHTML .= "<div id=\"category_link_box\">\n";
        $CategoriesHTML .= "<a href=\"/links/" . $cat->id . "\">" . $cat->name . "</a><br />\n";
        $CategoriesHTML .= "<span class=\"info_text\">" . $cat->description . "</span>\n";
        $CategoriesHTML .= "</div>\n";
    }


    my $Links = $c->model('DB::LinksLinks')->search({
        category_id => $cat,
	approved => 1,
    });
    
    my $LinksHTML;
    
    while (my $link = $Links->next) {
        $LinksHTML .= "<div id=\"category_link_box\">\n";
        $LinksHTML .= "<a href=\"" . $link->url . "\">" . $link->title . "</a></font><br />\n";
        $LinksHTML .= $link->details . "<br />\n";
        $LinksHTML .= "<i>" . $link->url . "</i>\n";
        $LinksHTML .= "</div>\n";
    }

    #$c->stash->{cat_word}        = 'Subcategories';
    $c->stash->{cat_word} = $cat_name;
    $c->stash->{categories_html} = $CategoriesHTML || 'No Subcategories Here';
    $c->stash->{links_html} = $LinksHTML;
    $c->stash->{template} = 'links/view_links.tt2';
}



sub add_link :Path('/links/add_link') :Args(0) {
    my ( $self, $c ) = @_;
    
    # Is this a form submission, or a new screen?
    
    if ($c->req->params->{'link_url'}) {
        
        my $url         = $c->req->params->{'link_url'};
        my $title       = $c->req->params->{'link_title'};
        my $description = $c->req->params->{'link_description'};
        my $category    = $c->req->params->{'link_category'};
        
        my $Link = $c->model('DB::LinksLinks')->create({
           category_id => $category,
           title       => $title,
           url         => $url,
           details     => $description,
           approved    => 0,
           modifydate  => undef,
           createdate  => undef,
        });
        
        
        
        $c->stash->{template} = 'links/add_link_done.tt2';
        
    } else {

        my $CategoriesHTML;
    
        # Can we get this from cache?
    
        # If not, build it, then cache it
    
        # Start with all non-top level categories
    
        my $Categories = $c->model('DB::LinksCategories')->search({
            'parent_category_id' => { '>', '0' }
        });

        my %cats;    
    
        while (my $cat = $Categories->next) {
            my $cat_id = $cat->id;
            my $parent_cat_id = $cat->parent_category_id;
            my $cat_name = $cat->name;
            
            while ($parent_cat_id > 1) {
                my $SearchCat = $c->model('DB::LinksCategories')->find({
                    id => $parent_cat_id,
                });
            
                #my $SearchCat = $SearchCategory->first;
                
                $cat_name = $SearchCat->name . " -> " . $cat_name;
                $parent_cat_id = $SearchCat->parent_category_id;
            }

            $cats{$cat_id} = $cat_name;
            #$CategoriesHTML .= "<option value=\"" . $cat_id . "\">" . $cat_name . "\n";
        }
        
        foreach (sort {$cats{$a} cmp $cats{$b} } keys %cats) {
            $CategoriesHTML .= "<option value=\"" . $_ . "\">" . $cats{$_} . "\n";
        }
    
        $c->stash->{categories_html} = $CategoriesHTML;
        $c->stash->{template} = 'links/add_link.tt2';
    }
}


__PACKAGE__->meta->make_immutable;

