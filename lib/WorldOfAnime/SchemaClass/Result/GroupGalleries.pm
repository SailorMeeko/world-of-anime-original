package WorldOfAnime::SchemaClass::Result::GroupGalleries;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("group_galleries");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "group_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "gallery_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "num_images",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "modifydate",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
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
__PACKAGE__->belongs_to(
  "group_galleries",
  "WorldOfAnime::SchemaClass::Result::Groups",
  { "foreign.id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "group_gallery_images",
  "WorldOfAnime::SchemaClass::Result::GroupGalleryImages",
  { "foreign.group_gallery_id" => "self.id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
