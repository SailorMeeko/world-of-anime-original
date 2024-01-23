package WorldOfAnime::SchemaClass::Result::DBChanges;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("db_changes");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "change_type_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "old_value_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "value",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
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

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
