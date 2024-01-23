package WorldOfAnime::SchemaClass::Result::ForumThreads;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("forum_threads");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "forum_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "started_by_user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "subject",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "views",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "last_post",
  {
    data_type => "DATETIME",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 19,
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
    data_type => "TIMESTAMP",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "forum_id",
  "WorldOfAnime::SchemaClass::Result::ForumForums",
  { id => "forum_id" },
);
__PACKAGE__->belongs_to(
  "started_by_user_id",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "started_by_user_id" },
);
__PACKAGE__->has_many(
  "thread_posts",
  "WorldOfAnime::SchemaClass::Result::ThreadPosts",
  { "foreign.thread_id" => "self.id" },
);
__PACKAGE__->has_many(
  "thread_subscriptions",
  "WorldOfAnime::SchemaClass::Result::ForumThreadSubscriptions",
  { "foreign.forum_thread_id" => "self.id" },
);
__PACKAGE__->format_columns;


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jSCM7GA1TzHOghGwZ2hayQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
