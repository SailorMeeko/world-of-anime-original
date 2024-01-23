package WorldOfAnime::SchemaClass::Result::ForumCategories;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("forum_categories");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "category_name",
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
__PACKAGE__->has_many(
  "forum_forums",
  "WorldOfAnime::SchemaClass::Result::ForumForums",
  { "foreign.category_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aihCbipWOSGsc/kXOn297g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
