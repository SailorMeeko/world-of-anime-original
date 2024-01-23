package WorldOfAnime::SchemaClass::Result::ArtStoryTitle;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("art_story_title");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "started_by_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "db_title_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "rating_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "title",
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
  "story_mode",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },   
  "publish",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },    
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
  "db_title_rel",
  "WorldOfAnime::SchemaClass::Result::DBTitles",
  { "foreign.static_id" => "self.db_title_id" },
);
__PACKAGE__->belongs_to(
  "rating",
  "WorldOfAnime::SchemaClass::Result::ArtStoryRatings",
  { id => "rating_id" },
);
__PACKAGE__->has_many(
  "chapters",
  "WorldOfAnime::SchemaClass::Result::ArtStoryChapter",
  { "foreign.story_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
