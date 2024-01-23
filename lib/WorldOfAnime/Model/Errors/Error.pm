package WorldOfAnime::Model::Errors::Error;
use Moose;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'user_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'error' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'user_agent' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'referer' => (
  is => 'rw',
  isa => 'Maybe[Str]',
);

has 'createdate' => (
    is => 'rw',
    isa => 'DateTime',
);


sub build {
    my $self = shift;
    my ( $c, $error ) = @_;
    
    my $viewer_id = WorldOfAnime::Controller::Helpers::Users::GetUserID($c);
    
    eval {
        my $Error = $c->model('DB::Errors')->create({
            user_id  => $viewer_id,
            error => $error,
            user_agent => $c->req->user_agent,
            referer => $c->req->referer,
            createdate => undef,
        });
    };
    
    if ($@) {
        my $Error = $c->model('DB::Errors')->create({
            user_id  => 0,
            error => $@ . " - " . $error,
            user_agent => "Generic User Agent",
            referer => "Generic Referer",
            createdate => undef,
        });
    }
    
}

1;