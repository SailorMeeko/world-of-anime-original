package WorldOfAnime::SchemaClass::Result::ForumForums;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("forum_forums");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "forum_name",
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
  "visible",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 3 },
  "display_order",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },  
  "modify_date",
  {
    data_type => "TIMESTAMP",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
  "create_date",
  {
    data_type => "TIMESTAMP",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "threads_to_forums",
  "WorldOfAnime::SchemaClass::Result::ForumThreads",
  { forum_id => "id" },
);
__PACKAGE__->belongs_to(
  "category_id",
  "WorldOfAnime::SchemaClass::Result::ForumCategories",
  { id => "category_id" },
);
__PACKAGE__->has_many(
  "forum_threads",
  "WorldOfAnime::SchemaClass::Result::ForumThreads",
  { "foreign.forum_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MTScC4zpwM1KeviCrQ/3cQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
