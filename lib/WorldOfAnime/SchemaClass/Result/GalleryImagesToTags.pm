package WorldOfAnime::SchemaClass::Result::GalleryImagesToTags;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("gallery_images_to_tags");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "active",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "gallery_image_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "tag_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "tagged_by",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "untagged_by",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 10 },  
  "create_date",
  {
    data_type => "DATETIME",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
  },
  "untagged_date",
  {
    data_type => "DATETIME",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 1,
    size => 14,
  },    
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  image_tag => [ qw/gallery_image_id tag_id/ ],
);
__PACKAGE__->belongs_to(
  "gallery_image",
  "WorldOfAnime::SchemaClass::Result::GalleryImages",
  { "foreign.id" => "self.gallery_image_id" },
);
__PACKAGE__->belongs_to(
  "tagger",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "tagged_by" },
);
__PACKAGE__->belongs_to(
  "untagger",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "untagged_by" },
);
__PACKAGE__->belongs_to(
  "tag",
  "WorldOfAnime::SchemaClass::Result::Tags",
  { "foreign.id" => "self.tag_id" },
);
__PACKAGE__->format_columns;


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
