package WorldOfAnime::SchemaClass::Result::BlogUserSubscriptions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("blog_user_subscriptions");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "subscriber_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "subscribed_to_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
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
__PACKAGE__->add_unique_constraint(subscription => [ qw/subscriber_user_id subscribed_to_user_id/ ]);
__PACKAGE__->belongs_to(
  "subscriber",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "subscriber_user_id" },
);
__PACKAGE__->belongs_to(
  "subscribed_to",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "subscribed_to_user_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSCM7GA1TzHOghGwZ2hayQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
