package WorldOfAnime::SchemaClass::Result::NewsArticles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("news_articles");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "title",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "article",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "teaser",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "short_url",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },   
  "pretty_url",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },  
  "source_url",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },   
  "source_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },    
  "status",
  # 0 => New (awaiting approval), 1 => Approved (display on site)
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 10 },   
  "posted_by",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "views",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "image_id",
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
__PACKAGE__->format_columns;

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSCM7GA1TzHOghGwZ2hayQ

__PACKAGE__->belongs_to(
  "submitted_by",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "posted_by" },
);

__PACKAGE__->belongs_to(
  "image",
  "WorldOfAnime::SchemaClass::Result::Images",
  { id => "image_id" },
);

# You can replace this text with custom content, and it will be preserved on regeneration
1;