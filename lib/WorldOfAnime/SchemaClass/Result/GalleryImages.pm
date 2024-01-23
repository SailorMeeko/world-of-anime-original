package WorldOfAnime::SchemaClass::Result::GalleryImages;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("gallery_images");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "gallery_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "image_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "num_views",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "active",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
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
    data_type => "DATETIME",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "image_gallery",
  "WorldOfAnime::SchemaClass::Result::Galleries",
  { "foreign.id" => "self.gallery_id" },
);
__PACKAGE__->belongs_to(
  "image_images",
  "WorldOfAnime::SchemaClass::Result::Images",
  { "foreign.id" => "self.image_id" },
);
__PACKAGE__->has_many(
  "gallery_image_comments",
  "WorldOfAnime::SchemaClass::Result::GalleryImageComments",
  { "foreign.gallery_image_id" => "self.id" },
);
__PACKAGE__->has_many(
  "gallery_image_favorites",
  "WorldOfAnime::SchemaClass::Result::FavoritesGalleryImages",
  { "foreign.gallery_image_id" => "self.id" },
);
__PACKAGE__->format_columns;

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
