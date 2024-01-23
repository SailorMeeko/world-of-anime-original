package WorldOfAnime::SchemaClass::Result::Images;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("images");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "is_s3",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },
  "is_deleted",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },
  "is_appropriate",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },      
  "filedir",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "filename",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "filetype",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 15,
  },
  "filesize",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "height",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "width",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
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
  "user_profile_image",
  "WorldOfAnime::SchemaClass::Result::UserProfile",
  { "profile_image_id" => "id" },
  { join_type => 'left' }
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aihCbipWOSGsc/kXOn297g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
