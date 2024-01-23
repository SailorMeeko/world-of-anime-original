package WorldOfAnime::SchemaClass::Result::UsersToRoles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("users_to_roles");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "role_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
);
__PACKAGE__->belongs_to(
  "role_id",
  "WorldOfAnime::SchemaClass::Result::Roles",
  { id => "role_id" },
);
__PACKAGE__->belongs_to(
  "user_id",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:++d9iY4p99ZQqluCCXFREA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
