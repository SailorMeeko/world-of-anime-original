package WorldOfAnime::SchemaClass::Result::Games;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("games");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "pretty_url",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },  
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "filename",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "width",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "height",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "play_count",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "game_type",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },  
  "image",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "embedurl",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },  
  "modifydate",
  {
    data_type => "TIMESTAMP",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
  "createdate",
  {
    data_type => "TIMESTAMP",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "plays",
  "WorldOfAnime::SchemaClass::Result::GamePlays",
  { "foreign.game_id" => "self.id" },
);
__PACKAGE__->has_many(
  "categories",
  "WorldOfAnime::SchemaClass::Result::GamesInCategories",
  { "foreign.game_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v8+JuK6fzOPF9pF5tG9Lbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
