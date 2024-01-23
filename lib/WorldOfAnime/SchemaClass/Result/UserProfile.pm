package WorldOfAnime::SchemaClass::Result::UserProfile;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "Core");
__PACKAGE__->table("user_profile");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 10 },
  "user_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "gender",
  { data_type => "ENUM", default_value => undef, is_nullable => 1, size => 1 },
  "birthday",
  { data_type => "DATE", default_value => undef, is_nullable => 1, size => 10, datetime_undef_if_invalid => 1 },
  "show_age",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 10 },  
  "show_gallery_to_all",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 10 },  
  "show_actions",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 10 },
  "show_visible",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 10 },  
  "about_me",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "timezone",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },  
  "twitter",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "signature",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },  
  "now_watching",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "now_playing",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "now_reading",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "now_doing",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "notify_announcements",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_friend_request",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_comment",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_group_comment",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },  
  "notify_group_image_comment",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_group_new_member",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_group_member_upload_image",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_image_comment",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_private_message",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_blog_comment",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },    
  "notify_friend_now_box",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },    
  "notify_friend_blog_post",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },    
  "notify_friend_upload_image",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },
  "notify_friend_new_review",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 3 },      
  "profile_image_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "background_profile_image_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
  "banner_profile_image_id",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },  
  "scroll_background",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 10 },      
  "repeat_x",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 10 },
  "repeat_y",
  { data_type => "TINYINT", default_value => undef, is_nullable => 1, size => 10 },        
  "modifydate",
  {
    data_type => "TIMESTAMP",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
  "createdate",
  {
    data_type => "TIMESTAMP",
    default_value => undef,
    is_nullable => 1,
    size => 14,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint(
  user_id => [ qw/user_id/ ],
);
__PACKAGE__->belongs_to(
  "user_id",
  "WorldOfAnime::SchemaClass::Result::Users",
  { id => "user_id" },
);
__PACKAGE__->belongs_to(
  "user_profile_image_id",
  "WorldOfAnime::SchemaClass::Result::Images",
  { id => "profile_image_id" },
);
__PACKAGE__->belongs_to(
  "user_background_profile_image_id",
  "WorldOfAnime::SchemaClass::Result::Images",
  { id => "background_profile_image_id" },
);
__PACKAGE__->belongs_to(
  "user_banner_profile_image_id",
  "WorldOfAnime::SchemaClass::Result::Images",
  { id => "banner_profile_image_id" },
);
__PACKAGE__->belongs_to(
  "last_action",
  "WorldOfAnime::SchemaClass::Result::LastAction",
  { "foreign.user_id" => "self.user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-04 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v8+JuK6fzOPF9pF5tG9Lbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
