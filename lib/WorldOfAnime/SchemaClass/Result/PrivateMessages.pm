package WorldOfAnime::SchemaClass::Result::PrivateMessages;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("private_messages");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "parent_pm",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },  
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "from_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "subject",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },    
  "message",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "is_read",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 10 },  
  "is_deleted",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 10 },  
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
  "messages_to_users",
  "WorldOfAnime::SchemaClass::Result::Users",
  { "foreign.id" => "self.user_id" },
);
__PACKAGE__->belongs_to(
  "messages_from_users",
  "WorldOfAnime::SchemaClass::Result::Users",
  { "foreign.id" => "self.from_user_id" },
);
__PACKAGE__->format_columns;

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
