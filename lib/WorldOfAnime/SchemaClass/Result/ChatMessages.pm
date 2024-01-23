package WorldOfAnime::SchemaClass::Result::ChatMessages;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("chat_messages");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "private",
  { data_type => "TINYINT", default_value => undef, is_nullable => 0, size => 3 },
  "to_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },  
  "message",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
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
__PACKAGE__->format_columns;
__PACKAGE__->belongs_to(
  "chat_user",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "user_id" },
);
__PACKAGE__->belongs_to(
  "to_user",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "to_user_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
