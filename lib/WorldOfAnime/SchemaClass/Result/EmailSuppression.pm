package WorldOfAnime::SchemaClass::Result::EmailSuppression;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("email_suppression");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
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
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  email => [ qw/email/ ],
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSCM7GA1TzHOghGwZ2hayQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
