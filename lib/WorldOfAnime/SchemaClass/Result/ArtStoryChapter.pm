package WorldOfAnime::SchemaClass::Result::ArtStoryChapter;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("art_story_chapter");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "story_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "chapter_num",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "chapter_title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "chapter_content",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
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
  "written_by",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "user_id" },
);
__PACKAGE__->belongs_to(
  "story",
  "WorldOfAnime::SchemaClass::Result::ArtStoryTitle",
  { id => "story_id" },
);
__PACKAGE__->has_many(
  "comments",
  "WorldOfAnime::SchemaClass::Result::ArtStoryComments",
  { "foreign.art_story_id" => "self.id" },
);
# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
