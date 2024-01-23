package WorldOfAnime::SchemaClass::Result::QAAnswers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("qa_answers");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "question_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "answered_by",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "answer",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },  
  "modify_date",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "create_date",
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
  "question",
  "WorldOfAnime::SchemaClass::Result::QAQuestions",
  { id => "question_id" },
);
__PACKAGE__->belongs_to(
  "answered_by_user",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "answered_by" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSCM7GA1TzHOghGwZ2hayQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
