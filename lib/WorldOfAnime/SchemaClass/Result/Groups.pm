package WorldOfAnime::SchemaClass::Result::Groups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("groups");
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
  "is_private",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "is_approve",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "created_by_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "profile_image_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "background_image_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "scroll_background",
  { data_type => "TINYINT", default_value => 0, is_nullable => 1, size => 10 },      
  "repeat_x",
  { data_type => "TINYINT", default_value => 1, is_nullable => 1, size => 10 },
  "repeat_y",
  { data_type => "TINYINT", default_value => 1, is_nullable => 1, size => 10 },          
  "modifydate",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "createdate",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "group_comments",
  "WorldOfAnime::SchemaClass::Result::GroupComments",
  { "foreign.group_id" => "self.id" },
);
__PACKAGE__->has_many(
  "group_members",
  "WorldOfAnime::SchemaClass::Result::GroupUsers",
  { "foreign.group_id" => "self.id" },
);
__PACKAGE__->has_many(
    "join_requests",
    "WorldOfAnime::SchemaClass::Result::GroupJoinRequests",
    { "foreign.group_id" => "self.id" },
);
__PACKAGE__->has_many(
    "logs",
    "WorldOfAnime::SchemaClass::Result::GroupLogs",
    { "foreign.group_id" => "self.id" },
);
__PACKAGE__->belongs_to(
  "group_creator",
  "WorldOfAnime::SchemaClass::Result::Users",
  { "foreign.id" => "self.created_by_user_id" },
);
__PACKAGE__->belongs_to(
  "groups_profile_image_id",
  "WorldOfAnime::SchemaClass::Result::Images",
  { id => "profile_image_id" },
);
__PACKAGE__->belongs_to(
  "groups_background_image_id",
  "WorldOfAnime::SchemaClass::Result::Images",
  { id => "background_image_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;