package WorldOfAnime::Model::Reviews::Review;
use Moose;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has 'user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'reviewer' => (
    is => 'rw',
    isa => 'Str',
);

has 'review' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'createdate' => (
    is => 'rw',
    isa => 'DateTime',
);

has 'comments' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'num_comments' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

1;