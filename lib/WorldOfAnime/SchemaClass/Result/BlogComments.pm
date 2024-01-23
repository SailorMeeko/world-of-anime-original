package WorldOfAnime::SchemaClass::Result::BlogComments;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("blog_comments");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "blog_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },  
  "comment",
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
__PACKAGE__->format_columns;

__PACKAGE__->belongs_to(
  "blog",
  "WorldOfAnime::SchemaClass::Result::Blogs",
  { "foreign.id" => "self.blog_id" },
);
__PACKAGE__->belongs_to(
  "blog_commentor",
  "WorldOfAnime::SchemaClass::Result::Users",
  { "foreign.id" => "self.user_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
