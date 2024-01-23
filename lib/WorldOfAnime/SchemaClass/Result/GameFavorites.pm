package WorldOfAnime::SchemaClass::Result::GameFavorites;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("game_favorites");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "game_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
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
__PACKAGE__->belongs_to(
  "game",
  "WorldOfAnime::SchemaClass::Result::Games",
  { "foreign.id" => "self.game_id" },
);
__PACKAGE__->belongs_to(
  "user",
  "WorldOfAnime::SchemaClass::Result::Users",
  { "foreign.id" => "self.user_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v8+JuK6fzOPF9pF5tG9Lbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
