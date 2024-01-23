package WorldOfAnime::Model::Database::Title;
use Moose;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'static_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'english_title' => (
  is => 'rw',
);

has 'japanese_title' => (
  is => 'rw',
);

has 'pretty_title' => (
  is => 'rw',
);

has 'description' => (
  is => 'rw',
);

has 'publish_year' => (
  is => 'rw',
  isa => 'Maybe[Int]',
);

has 'profile_image_id' => (
  is => 'rw',
  isa => 'Int',
);

has 'filedir' => (
  is => 'rw',
  isa => 'Str',
);

has 'filename' => (
  is => 'rw',
  isa => 'Str',
);

has 'image_height' => (
  is => 'rw',
  isa => 'Int',
);

has 'image_width' => (
  is => 'rw',
  isa => 'Int',
);




1;