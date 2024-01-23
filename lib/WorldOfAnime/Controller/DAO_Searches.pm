package WorldOfAnime::Controller::DAO_Searches;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub RecordSearch :Local {
    my ( $c, $type, $string, $count) = @_;
    
    my $id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    $c->model('DB::SearchesGeneric')->create({
        search_type => $type,
        user_id => $id,
        search_string => $string,
        num_results => $count,
        create_date => undef,
    });
}

__PACKAGE__->meta->make_immutable;

1;
