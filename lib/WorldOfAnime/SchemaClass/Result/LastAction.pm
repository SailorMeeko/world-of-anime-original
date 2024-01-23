package WorldOfAnime::SchemaClass::Result::LastAction;

use strict;
no warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("lastaction");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "lastaction",
  {
    data_type => "DATETIME",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
  },    
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("user_id", ["user_id"]);
__PACKAGE__->belongs_to(
  "users",
  "WorldOfAnime::SchemaClass::Result::Users",
  { "foreign.id" => "self.user_id" },
);
__PACKAGE__->belongs_to(
  "user_profiles",
  "WorldOfAnime::SchemaClass::Result::UserProfile",
  { "foreign.user_id" => "self.user_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration

1;
