package WorldOfAnime::SchemaClass::Result::DBRatings;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("db_ratings");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "db_title_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "rating",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },    
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "rated_by",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "user_id" },
);
# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
