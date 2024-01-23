package WorldOfAnime::SchemaClass::Result::DBTitles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("db_titles");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "static_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "active",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },    
  "started_by_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "english_title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "japanese_title",
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
  "publish_year",
  { data_type => "SMALLINT", default_value => undef, is_nullable => 0, size => 8 },
  "num_episodes",
  { data_type => "SMALLINT", default_value => undef, is_nullable => 0, size => 8 },
  "episode_length",
  { data_type => "SMALLINT", default_value => undef, is_nullable => 0, size => 8 },  
  "profile_image_id",
  { data_type => "INT", default_value => 3, is_nullable => 1, size => 10 },  
  "modifydate",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "createdate",
  {
    data_type => "DATETIME",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "started_by",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "started_by_user_id" },
);
__PACKAGE__->belongs_to(
  "category",
  "WorldOfAnime::SchemaClass::Result::DBCategories",
  { id => "category_id" },
);
__PACKAGE__->belongs_to(
  "anime_profile_image_id",
  "WorldOfAnime::SchemaClass::Result::Images",
  { id => "profile_image_id" },
);
__PACKAGE__->has_many(
  "titles_to_genres",
  "WorldOfAnime::SchemaClass::Result::DBTitlesToGenres",
  { "foreign.db_title_id" => "self.static_id" },
);
__PACKAGE__->has_many(
  "episodes",
  "WorldOfAnime::SchemaClass::Result::DBTitlesEpisodes",
  { "foreign.db_title_id" => "self.static_id" },
);
__PACKAGE__->many_to_many(
  "genres" => 'titles_to_genres', 'genre_id'
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
