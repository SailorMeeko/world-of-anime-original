package WorldOfAnime::SchemaClass::Result::SearchesGeneric;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("searches_generic");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "search_type",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },  
  "search_string",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "num_results",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },     
  "create_date",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
