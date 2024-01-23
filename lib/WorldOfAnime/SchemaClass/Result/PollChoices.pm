package WorldOfAnime::SchemaClass::Result::PollChoices;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("poll_choices");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "poll_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "choice",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "votes",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },  
  "status",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 10 },
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
  "poll_question",
  "WorldOfAnime::SchemaClass::Result::PollQuestions",
  { id => "poll_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSCM7GA1TzHOghGwZ2hayQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
