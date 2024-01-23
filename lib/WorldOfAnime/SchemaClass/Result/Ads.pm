package WorldOfAnime::SchemaClass::Result::Ads;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("ads");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "affiliate_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "size_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "html_code",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "active",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },  
  "displays",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "max_displays",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },
  "require_approval",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },    
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
__PACKAGE__->belongs_to(
  "sizes",
  "WorldOfAnime::SchemaClass::Result::AdSizes",
  { id => "size_id" },
);
__PACKAGE__->belongs_to(
  "affiliates",
  "WorldOfAnime::SchemaClass::Result::AdAffiliates",
  { id => "affiliate_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSCM7GA1TzHOghGwZ2hayQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
