package WorldOfAnime::Controller::Chat;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched WorldOfAnime::Controller::Chat in Chat.');
}


sub chat :Path('/chat') :Args(0) {
    my ( $self, $c ) = @_;
    
    if ($c->user_exists() ) {
        my $UserID = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);

        my $User = $c->model("DB::Users")->find({
            id => $UserID
        });
    
        if ($User->username) {
            $c->stash->{username} = $User->username;
        }
    }
    
    $c->stash->{images_approved} = 1;    
    $c->stash->{template} = 'chat/chat.tt2';
}


__PACKAGE__->meta->make_immutable;

