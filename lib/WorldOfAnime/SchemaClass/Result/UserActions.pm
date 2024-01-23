package WorldOfAnime::SchemaClass::Result::UserActions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("user_actions");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "action_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "action_object",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "points",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },  
  "modify_date",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "create_date",
  {
    data_type => "TIMESTAMP",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->format_columns;
__PACKAGE__->belongs_to(
  "users",
  "WorldOfAnime::SchemaClass::Result::Users",
  { "foreign.id" => "self.user_id" },
);
__PACKAGE__->belongs_to(
  "actions",
  "WorldOfAnime::SchemaClass::Result::Actions",
  { "foreign.id" => "self.action_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
