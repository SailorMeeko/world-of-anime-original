package WorldOfAnime::SchemaClass::Result::DBTitlesToGenres;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("db_titles_to_genres");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "active",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },     
  "from_title_edit",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "db_title_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "db_genre_id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },  
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "title_id",
  "WorldOfAnime::SchemaClass::Result::DBTitles",
  { static_id => "db_title_id" },
);
__PACKAGE__->belongs_to(
  "genre_id",
  "WorldOfAnime::SchemaClass::Result::DBGenres",
  { id => "db_genre_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U10VfAqRRKvMJuLZcrxeiA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
