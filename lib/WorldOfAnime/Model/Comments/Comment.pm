package WorldOfAnime::Model::Comments::Comment;
use Moose;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'type' => (
    is => 'rw',
    isa => 'Int',
);

has 'commenter_id' => (
# This is who made the comment
    is => 'rw',
    isa => 'Int',
);

has 'comment' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'createdate' => (
    is => 'rw',
    isa => 'Maybe[DateTime]',
);


# Comment types:
#
# 1 = Profile Comment


1;