package WorldOfAnime::SchemaClass::Result::UserProfileSiteNotifications;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("user_profile_site_notifications");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "notification",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "receive",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 10 },  
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  user_id => [ qw/user_id/ ],
);
__PACKAGE__->add_unique_constraint(
  user_notification => [ qw/user_id notification/ ],
);
__PACKAGE__->belongs_to(
  "user_id",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v8+JuK6fzOPF9pF5tG9Lbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
