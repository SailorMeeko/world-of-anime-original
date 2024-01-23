package WorldOfAnime::Model::Polls::PollChoices;
use Moose;
use JSON;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'poll_id' => (
    is => 'rw',
    isa => 'Int',
);


__PACKAGE__->meta->make_immutable;

1;
