package WorldOfAnime::SchemaClass::Result::Timezones;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("timezones");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "timezone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },  
);
__PACKAGE__->set_primary_key("id");

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
