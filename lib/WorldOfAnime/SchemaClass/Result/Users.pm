package WorldOfAnime::SchemaClass::Result::Users;

use strict;
no warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "FormatColumns", "Core");
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "uuid",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 36,
  },
  "username",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "password",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "status",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "points",
  { data_type => "INT", default_value => 0, is_nullable => 1, size => 11 },
  "referred_by",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "confirmdate",
  {
    data_type => "DATETIME",
    default_value => "0000-00-00 00:00:00",
    is_nullable => 0,
    size => 14,
    datetime_undef_if_invalid => 1,
  },
  "join_ip_address",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "last_login_ip_address",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "verified_non_spammer",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 3 },     
  "modifydate",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
  "createdate",
  {
    data_type => "TIMESTAMP",
    default_value => "CURRENT_TIMESTAMP",
    is_nullable => 0,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("Username", ["username"]);
__PACKAGE__->add_unique_constraint("id", ["id"]);
__PACKAGE__->add_unique_constraint("Email", ["email"]);
__PACKAGE__->belongs_to(
  "last_action",
  "WorldOfAnime::SchemaClass::Result::LastAction",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->belongs_to(
  "user_profiles",
  "WorldOfAnime::SchemaClass::Result::UserProfile",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->belongs_to(
  "user_status",
  "WorldOfAnime::SchemaClass::Result::UserStatuses",
  { id => "status" },
);
__PACKAGE__->has_many(
  "user_profiles_site_notifications",
  "WorldOfAnime::SchemaClass::Result::UserProfileSiteNotifications",
  { "foreign.user_id" => "self.id" },
);

__PACKAGE__->has_many(
  "user_images",
  "WorldOfAnime::SchemaClass::Result::Images",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_to_favorite_anime",
  "WorldOfAnime::SchemaClass::Result::UserFavoriteAnime",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_to_favorite_movie",
  "WorldOfAnime::SchemaClass::Result::UserFavoriteMovies",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_comments",
  "WorldOfAnime::SchemaClass::Result::UserComments",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_actions",
  "WorldOfAnime::SchemaClass::Result::UserActions",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "latest_activity",
  "WorldOfAnime::SchemaClass::Result::LatestActivity",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_notifications",
  "WorldOfAnime::SchemaClass::Result::Notifications",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_friends",
  "WorldOfAnime::SchemaClass::Result::UserFriends",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "blocked_users",
  "WorldOfAnime::SchemaClass::Result::UserBlocks",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_thread_subscriptions",
  "WorldOfAnime::SchemaClass::Result::ForumThreadSubscriptions",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "user_blog_subscriptions",
  "WorldOfAnime::SchemaClass::Result::BlogSubscriptions",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
    "art_story_subscriptions",
    "WorldOfAnime::SchemaClass::Result::ArtStorySubscriptions",
    { "foreign.subscriber_user_id" => "self.id" },
);
__PACKAGE__->has_many(
    "favorite_gallery_images",
    "WorldOfAnime::SchemaClass::Result::FavoritesGalleryImages",
    { "foreign.user_id" => "self.id" },
);
__PACKAGE__->has_many(
  "users_to_roles",
  "WorldOfAnime::SchemaClass::Result::UsersToRoles",
  { "foreign.user_id" => "self.id" },
);
__PACKAGE__->many_to_many(
	"roles" => 'users_to_roles', 'role_id'
);
__PACKAGE__->format_columns;

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-07 16:07:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Uk5sqVCaXQRbYYTPY482yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
