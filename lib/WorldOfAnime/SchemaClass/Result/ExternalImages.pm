package WorldOfAnime::SchemaClass::Result::ExternalImages;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("external_images");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "url",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 1000,
  },
  "is_approved",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },      
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aihCbipWOSGsc/kXOn297g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
