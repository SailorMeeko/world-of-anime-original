package WorldOfAnime::SchemaClass::Result::DBTitlesEpisodes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("db_titles_episodes");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "active",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },  
  "added_by_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "db_title_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "episode_number",
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
  "original_airdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10, datetime_undef_if_invalid => 1 },
  "english_airdate",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10, datetime_undef_if_invalid => 1 },
  "length",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 }, 
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },  
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
  "added_by",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "added_by_user_id" },
);
__PACKAGE__->belongs_to(
  "title",
  "WorldOfAnime::SchemaClass::Result::DBTitles",
  { static_id => "db_title_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
