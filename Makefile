# This Makefile is for the WorldOfAnime extension to perl.
#
# It was generated automatically by MakeMaker version
# 6.64 (Revision: 66400) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#       ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker ARGV: ()
#

#   MakeMaker Parameters:

#     AUTHOR => []
#     BUILD_REQUIRES => { ExtUtils::MakeMaker=>q[6.36] }
#     CONFIGURE_REQUIRES => {  }
#     DISTNAME => q[WorldOfAnime]
#     EXE_FILES => [q[script/worldofanime_cgi.pl], q[script/worldofanime_create.pl], q[script/worldofanime_fastcgi.pl], q[script/worldofanime_server.pl], q[script/worldofanime_test.pl]]
#     NAME => q[WorldOfAnime]
#     NO_META => q[1]
#     PREREQ_PM => { parent=>q[0], Catalyst::Plugin::Static::Simple=>q[0], ExtUtils::MakeMaker=>q[6.36], Catalyst::Plugin::ConfigLoader=>q[0], Config::General=>q[0], Catalyst::Runtime=>q[5.80007], Catalyst::Action::RenderView=>q[0] }
#     TEST_REQUIRES => {  }
#     VERSION => q[1.0]
#     VERSION_FROM => q[lib/WorldOfAnime.pm]
#     dist => { PREOP=>q[$(PERL) -I. "-MModule::Install::Admin" -e "dist_preop(q($(DISTVNAME)))"] }
#     realclean => { FILES=>q[MYMETA.yml] }
#     test => { TESTS=>q[t/01app.t t/02pod.t t/03podcoverage.t t/controller_Anime.t t/controller_ArtStory.t t/controller_DAO_Anime.t t/controller_DAO_ArtStory.t t/controller_DAO_Blogs.t t/controller_DAO_Comments.t t/controller_DAO_Favorites.t t/controller_DAO_Format.t t/controller_DAO_Forums.t t/controller_DAO_Friends.t t/controller_DAO_Games.t t/controller_DAO_Groups.t t/controller_DAO_ImageTags.t t/controller_DAO_Messages.t t/controller_DAO_News.t t/controller_DAO_Searches.t t/controller_DAO_Tags.t t/controller_Favorites.t t/controller_Forums.t t/controller_Games.t t/controller_Image.t t/controller_ImageGalleries.t t/controller_ImageTags.t t/controller_Messages.t t/controller_Moderate.t t/controller_News.t t/controller_Polls.t t/controller_Profile.t t/controller_Tags.t t/controller_Users.t t/model_Anime.t t/model_DB.t t/model_Galleries-Gallery.t t/model_Galleries-UserGalleries.t t/model_Gallery-UserGalleries.t t/model_Images-GalleryImage.t t/model_Images-Image.t t/model_Messages-PrivateMessage.t t/model_Messages-Thread.t t/model_Messages-UserMessages.t t/model_Polls-PollChoices.t t/model_Polls-Polls.t t/model_Session.t t/model_Users-UserEmailNotifications.t t/model_Users.t t/view_Email.t t/view_JSON.t t/view_Thumbnail.t] }

# --- MakeMaker post_initialize section:


# --- MakeMaker const_config section:

# These definitions are from config.sh (via /usr/lib/perl/5.10/Config.pm).
# They may have been overridden via Makefile.PL or on the command line.
AR = ar
CC = cc
CCCDLFLAGS = -fPIC
CCDLFLAGS = -Wl,-E
DLEXT = so
DLSRC = dl_dlopen.xs
EXE_EXT = 
FULL_AR = /usr/bin/ar
LD = cc
LDDLFLAGS = -shared -O2 -g -L/usr/local/lib -fstack-protector
LDFLAGS =  -fstack-protector -L/usr/local/lib
LIBC = /lib/libc-2.11.1.so
LIB_EXT = .a
OBJ_EXT = .o
OSNAME = linux
OSVERS = 2.6.42-23-generic
RANLIB = :
SITELIBEXP = /usr/local/share/perl/5.10.1
SITEARCHEXP = /usr/local/lib/perl/5.10.1
SO = so
VENDORARCHEXP = /usr/lib/perl5
VENDORLIBEXP = /usr/share/perl5


# --- MakeMaker constants section:
AR_STATIC_ARGS = cr
DIRFILESEP = /
DFSEP = $(DIRFILESEP)
NAME = WorldOfAnime
NAME_SYM = WorldOfAnime
VERSION = 1.0
VERSION_MACRO = VERSION
VERSION_SYM = 1_0
DEFINE_VERSION = -D$(VERSION_MACRO)=\"$(VERSION)\"
XS_VERSION = 1.0
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"
INST_ARCHLIB = blib/arch
INST_SCRIPT = blib/script
INST_BIN = blib/bin
INST_LIB = blib/lib
INST_MAN1DIR = blib/man1
INST_MAN3DIR = blib/man3
MAN1EXT = 1p
MAN3EXT = 3pm
INSTALLDIRS = site
DESTDIR = 
PREFIX = $(SITEPREFIX)
PERLPREFIX = /usr
SITEPREFIX = /usr/local
VENDORPREFIX = /usr
INSTALLPRIVLIB = /usr/share/perl/5.10
DESTINSTALLPRIVLIB = $(DESTDIR)$(INSTALLPRIVLIB)
INSTALLSITELIB = /usr/local/share/perl/5.10.1
DESTINSTALLSITELIB = $(DESTDIR)$(INSTALLSITELIB)
INSTALLVENDORLIB = /usr/share/perl5
DESTINSTALLVENDORLIB = $(DESTDIR)$(INSTALLVENDORLIB)
INSTALLARCHLIB = /usr/lib/perl/5.10
DESTINSTALLARCHLIB = $(DESTDIR)$(INSTALLARCHLIB)
INSTALLSITEARCH = /usr/local/lib/perl/5.10.1
DESTINSTALLSITEARCH = $(DESTDIR)$(INSTALLSITEARCH)
INSTALLVENDORARCH = /usr/lib/perl5
DESTINSTALLVENDORARCH = $(DESTDIR)$(INSTALLVENDORARCH)
INSTALLBIN = /usr/bin
DESTINSTALLBIN = $(DESTDIR)$(INSTALLBIN)
INSTALLSITEBIN = /usr/local/bin
DESTINSTALLSITEBIN = $(DESTDIR)$(INSTALLSITEBIN)
INSTALLVENDORBIN = /usr/bin
DESTINSTALLVENDORBIN = $(DESTDIR)$(INSTALLVENDORBIN)
INSTALLSCRIPT = /usr/bin
DESTINSTALLSCRIPT = $(DESTDIR)$(INSTALLSCRIPT)
INSTALLSITESCRIPT = /usr/local/bin
DESTINSTALLSITESCRIPT = $(DESTDIR)$(INSTALLSITESCRIPT)
INSTALLVENDORSCRIPT = /usr/bin
DESTINSTALLVENDORSCRIPT = $(DESTDIR)$(INSTALLVENDORSCRIPT)
INSTALLMAN1DIR = /usr/share/man/man1
DESTINSTALLMAN1DIR = $(DESTDIR)$(INSTALLMAN1DIR)
INSTALLSITEMAN1DIR = /usr/local/man/man1
DESTINSTALLSITEMAN1DIR = $(DESTDIR)$(INSTALLSITEMAN1DIR)
INSTALLVENDORMAN1DIR = /usr/share/man/man1
DESTINSTALLVENDORMAN1DIR = $(DESTDIR)$(INSTALLVENDORMAN1DIR)
INSTALLMAN3DIR = /usr/share/man/man3
DESTINSTALLMAN3DIR = $(DESTDIR)$(INSTALLMAN3DIR)
INSTALLSITEMAN3DIR = /usr/local/man/man3
DESTINSTALLSITEMAN3DIR = $(DESTDIR)$(INSTALLSITEMAN3DIR)
INSTALLVENDORMAN3DIR = /usr/share/man/man3
DESTINSTALLVENDORMAN3DIR = $(DESTDIR)$(INSTALLVENDORMAN3DIR)
PERL_LIB =
PERL_ARCHLIB = /usr/lib/perl/5.10
LIBPERL_A = libperl.a
FIRST_MAKEFILE = Makefile
MAKEFILE_OLD = Makefile.old
MAKE_APERL_FILE = Makefile.aperl
PERLMAINCC = $(CC)
PERL_INC = /usr/lib/perl/5.10/CORE
PERL = /usr/bin/perl "-Iinc"
FULLPERL = /usr/bin/perl "-Iinc"
ABSPERL = $(PERL)
PERLRUN = $(PERL)
FULLPERLRUN = $(FULLPERL)
ABSPERLRUN = $(ABSPERL)
PERLRUNINST = $(PERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
FULLPERLRUNINST = $(FULLPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
ABSPERLRUNINST = $(ABSPERLRUN) "-I$(INST_ARCHLIB)" "-Iinc" "-I$(INST_LIB)"
PERL_CORE = 0
PERM_DIR = 755
PERM_RW = 644
PERM_RWX = 755

MAKEMAKER   = /usr/local/share/perl/5.10.1/ExtUtils/MakeMaker.pm
MM_VERSION  = 6.64
MM_REVISION = 66400

# FULLEXT = Pathname for extension directory (eg Foo/Bar/Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT. (eg Oracle)
# PARENT_NAME = NAME without BASEEXT and no trailing :: (eg Foo::Bar)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
MAKE = make
FULLEXT = WorldOfAnime
BASEEXT = WorldOfAnime
PARENT_NAME = 
DLBASE = $(BASEEXT)
VERSION_FROM = lib/WorldOfAnime.pm
OBJECT = 
LDFROM = $(OBJECT)
LINKTYPE = dynamic
BOOTDEP = 

# Handy lists of source code files:
XS_FILES = 
C_FILES  = 
O_FILES  = 
H_FILES  = 
MAN1PODS = script/worldofanime_cgi.pl \
	script/worldofanime_create.pl \
	script/worldofanime_fastcgi.pl \
	script/worldofanime_server.pl \
	script/worldofanime_test.pl
MAN3PODS = lib/WorldOfAnime/Controller/DAO_Forums.pm \
	lib/WorldOfAnime/Model/Anime.pm \
	lib/WorldOfAnime/Model/AnimeCacheable.pm \
	lib/WorldOfAnime/Model/DB.pm \
	lib/WorldOfAnime/Model/Images.pm \
	lib/WorldOfAnime/View/HTML.pm \
	lib/WorldOfAnime/View/JSON.pm

# Where is the Config information that we are using/depend on
CONFIGDEP = $(PERL_ARCHLIB)$(DFSEP)Config.pm $(PERL_INC)$(DFSEP)config.h

# Where to build things
INST_LIBDIR      = $(INST_LIB)
INST_ARCHLIBDIR  = $(INST_ARCHLIB)

INST_AUTODIR     = $(INST_LIB)/auto/$(FULLEXT)
INST_ARCHAUTODIR = $(INST_ARCHLIB)/auto/$(FULLEXT)

INST_STATIC      = 
INST_DYNAMIC     = 
INST_BOOT        = 

# Extra linker info
EXPORT_LIST        = 
PERL_ARCHIVE       = 
PERL_ARCHIVE_AFTER = 


TO_INST_PM = CreateStagedEmails.pl \
	SendWaitingEmailsHTML.pl \
	lib/WorldOfAnime.pm \
	lib/WorldOfAnime/Controller/Admin.pm \
	lib/WorldOfAnime/Controller/Anime.pm \
	lib/WorldOfAnime/Controller/ArtStory.pm \
	lib/WorldOfAnime/Controller/Blogs.pm \
	lib/WorldOfAnime/Controller/Chat.pm \
	lib/WorldOfAnime/Controller/Chat.pm.old \
	lib/WorldOfAnime/Controller/DAO_Anime.pm \
	lib/WorldOfAnime/Controller/DAO_ArtStory.pm \
	lib/WorldOfAnime/Controller/DAO_Blogs.pm \
	lib/WorldOfAnime/Controller/DAO_Comments.pm \
	lib/WorldOfAnime/Controller/DAO_Email.pm \
	lib/WorldOfAnime/Controller/DAO_Favorites.pm \
	lib/WorldOfAnime/Controller/DAO_Format.pm \
	lib/WorldOfAnime/Controller/DAO_Forums.pm \
	lib/WorldOfAnime/Controller/DAO_Friends.pm \
	lib/WorldOfAnime/Controller/DAO_Games.pm \
	lib/WorldOfAnime/Controller/DAO_Groups.pm \
	lib/WorldOfAnime/Controller/DAO_ImageTags.pm \
	lib/WorldOfAnime/Controller/DAO_Images.pm \
	lib/WorldOfAnime/Controller/DAO_Messages.pm \
	lib/WorldOfAnime/Controller/DAO_News.pm \
	lib/WorldOfAnime/Controller/DAO_Searches.pm \
	lib/WorldOfAnime/Controller/DAO_Tags.pm \
	lib/WorldOfAnime/Controller/DAO_Users.pm \
	lib/WorldOfAnime/Controller/Email.pm \
	lib/WorldOfAnime/Controller/Favorites.pm \
	lib/WorldOfAnime/Controller/Forums.pm \
	lib/WorldOfAnime/Controller/Games.pm \
	lib/WorldOfAnime/Controller/Groups.pm \
	lib/WorldOfAnime/Controller/Image.pm \
	lib/WorldOfAnime/Controller/ImageGalleries.pm \
	lib/WorldOfAnime/Controller/ImageTags.pm \
	lib/WorldOfAnime/Controller/Links.pm \
	lib/WorldOfAnime/Controller/Messages.pm \
	lib/WorldOfAnime/Controller/Moderate.pm \
	lib/WorldOfAnime/Controller/News.pm \
	lib/WorldOfAnime/Controller/Notifications.pm \
	lib/WorldOfAnime/Controller/Polls.pm \
	lib/WorldOfAnime/Controller/Profile.pm \
	lib/WorldOfAnime/Controller/QA.pm \
	lib/WorldOfAnime/Controller/Root.pm \
	lib/WorldOfAnime/Controller/Search.pm \
	lib/WorldOfAnime/Controller/Tags.pm \
	lib/WorldOfAnime/Controller/Users.pm \
	lib/WorldOfAnime/Model/Anime.pm \
	lib/WorldOfAnime/Model/AnimeCacheable.pm \
	lib/WorldOfAnime/Model/Art/Story.pm \
	lib/WorldOfAnime/Model/Art/StoryChapter.pm \
	lib/WorldOfAnime/Model/Comments/Comment.pm \
	lib/WorldOfAnime/Model/Comments/ProfileComment.pm \
	lib/WorldOfAnime/Model/DB.pm \
	lib/WorldOfAnime/Model/Database/AnimeTitle.pm \
	lib/WorldOfAnime/Model/Database/Title.pm \
	lib/WorldOfAnime/Model/Formatter.pm \
	lib/WorldOfAnime/Model/Galleries/Gallery.pm \
	lib/WorldOfAnime/Model/Galleries/UserGalleries.pm \
	lib/WorldOfAnime/Model/Groups/Group.pm \
	lib/WorldOfAnime/Model/Groups/GroupMembers.pm \
	lib/WorldOfAnime/Model/Images.pm \
	lib/WorldOfAnime/Model/Images/GalleryImage.pm \
	lib/WorldOfAnime/Model/Images/Image.pm \
	lib/WorldOfAnime/Model/Messages/PrivateMessage.pm \
	lib/WorldOfAnime/Model/Messages/Thread.pm \
	lib/WorldOfAnime/Model/Messages/UserMessages.pm \
	lib/WorldOfAnime/Model/Polls/Poll.pm \
	lib/WorldOfAnime/Model/Polls/PollChoices.pm \
	lib/WorldOfAnime/Model/Reviews/AnimeReview.pm \
	lib/WorldOfAnime/Model/Reviews/Review.pm \
	lib/WorldOfAnime/Model/S3.pm \
	lib/WorldOfAnime/Model/URL.pm \
	lib/WorldOfAnime/Model/Users/User.pm \
	lib/WorldOfAnime/Model/Users/UserProfile.pm \
	lib/WorldOfAnime/Model/Users/UserProfileAppearance.pm \
	lib/WorldOfAnime/SchemaClass.pm \
	lib/WorldOfAnime/SchemaClass/Result/Actions.pm \
	lib/WorldOfAnime/SchemaClass/Result/AdAffiliates.pm \
	lib/WorldOfAnime/SchemaClass/Result/AdSizes.pm \
	lib/WorldOfAnime/SchemaClass/Result/Ads.pm \
	lib/WorldOfAnime/SchemaClass/Result/AnimeTitles.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryChapter.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryRatings.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStorySubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryTitle.pm \
	lib/WorldOfAnime/SchemaClass/Result/BlogComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/BlogSubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/BlogUserSubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/Blogs.pm \
	lib/WorldOfAnime/SchemaClass/Result/ChatMessages.pm \
	lib/WorldOfAnime/SchemaClass/Result/ChatUsers.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBChangeTypes.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBChanges.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBGenres.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBRatings.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitleReviewComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitleReviews.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitles.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitlesEpisodes.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitlesToGenres.pm \
	lib/WorldOfAnime/SchemaClass/Result/EmailSuppression.pm \
	lib/WorldOfAnime/SchemaClass/Result/EmailTemplates.pm \
	lib/WorldOfAnime/SchemaClass/Result/Emails.pm \
	lib/WorldOfAnime/SchemaClass/Result/FavoritesGalleryImages.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumForums.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumThreadSubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumThreads.pm \
	lib/WorldOfAnime/SchemaClass/Result/Galleries.pm \
	lib/WorldOfAnime/SchemaClass/Result/GalleryImageComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/GalleryImages.pm \
	lib/WorldOfAnime/SchemaClass/Result/GalleryImagesToTags.pm \
	lib/WorldOfAnime/SchemaClass/Result/GameCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/GameFavorites.pm \
	lib/WorldOfAnime/SchemaClass/Result/GamePlays.pm \
	lib/WorldOfAnime/SchemaClass/Result/Games.pm \
	lib/WorldOfAnime/SchemaClass/Result/GamesInCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupCommentReplies.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupGalleries.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImageComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImages.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupInvites.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupJoinRequests.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupLogs.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupUsers.pm \
	lib/WorldOfAnime/SchemaClass/Result/Groups.pm \
	lib/WorldOfAnime/SchemaClass/Result/Images.pm \
	lib/WorldOfAnime/SchemaClass/Result/LastAction.pm \
	lib/WorldOfAnime/SchemaClass/Result/LinksCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/LinksLinks.pm \
	lib/WorldOfAnime/SchemaClass/Result/Logins.pm \
	lib/WorldOfAnime/SchemaClass/Result/MovieTitles.pm \
	lib/WorldOfAnime/SchemaClass/Result/NewsArticleComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/NewsArticles.pm \
	lib/WorldOfAnime/SchemaClass/Result/Notifications.pm \
	lib/WorldOfAnime/SchemaClass/Result/PollChoices.pm \
	lib/WorldOfAnime/SchemaClass/Result/PollQuestions.pm \
	lib/WorldOfAnime/SchemaClass/Result/PrivateMessages.pm \
	lib/WorldOfAnime/SchemaClass/Result/QAAnswers.pm \
	lib/WorldOfAnime/SchemaClass/Result/QAQuestions.pm \
	lib/WorldOfAnime/SchemaClass/Result/QASubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/Referrals.pm \
	lib/WorldOfAnime/SchemaClass/Result/Roles.pm \
	lib/WorldOfAnime/SchemaClass/Result/Searches.pm \
	lib/WorldOfAnime/SchemaClass/Result/SearchesGeneric.pm \
	lib/WorldOfAnime/SchemaClass/Result/Sessions.pm \
	lib/WorldOfAnime/SchemaClass/Result/StagingEmails.pm \
	lib/WorldOfAnime/SchemaClass/Result/StagingNotifications.pm \
	lib/WorldOfAnime/SchemaClass/Result/Stats.pm \
	lib/WorldOfAnime/SchemaClass/Result/Tags.pm \
	lib/WorldOfAnime/SchemaClass/Result/ThreadPosts.pm \
	lib/WorldOfAnime/SchemaClass/Result/Timezones.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserActions.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserBlocks.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserFavoriteAnime.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserFavoriteMovies.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserFriends.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserProfile.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserProfileSiteNotifications.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserStatuses.pm \
	lib/WorldOfAnime/SchemaClass/Result/Users.pm \
	lib/WorldOfAnime/SchemaClass/Result/UsersToRoles.pm \
	lib/WorldOfAnime/View/HTML.pm \
	lib/WorldOfAnime/View/JSON.pm \
	lib/WorldOfAnime/View/Plain.pm \
	scratch.pm

PM_TO_BLIB = lib/WorldOfAnime/Controller/Blogs.pm \
	blib/lib/WorldOfAnime/Controller/Blogs.pm \
	lib/WorldOfAnime/SchemaClass/Result/Emails.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Emails.pm \
	lib/WorldOfAnime/Controller/DAO_Users.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Users.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserBlocks.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserBlocks.pm \
	lib/WorldOfAnime/Model/Database/Title.pm \
	blib/lib/WorldOfAnime/Model/Database/Title.pm \
	lib/WorldOfAnime/Controller/Chat.pm.old \
	blib/lib/WorldOfAnime/Controller/Chat.pm.old \
	lib/WorldOfAnime/Controller/DAO_Email.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Email.pm \
	lib/WorldOfAnime/Controller/DAO_Groups.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Groups.pm \
	lib/WorldOfAnime/Model/Anime.pm \
	blib/lib/WorldOfAnime/Model/Anime.pm \
	lib/WorldOfAnime/Controller/DAO_Blogs.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Blogs.pm \
	lib/WorldOfAnime/Model/Database/AnimeTitle.pm \
	blib/lib/WorldOfAnime/Model/Database/AnimeTitle.pm \
	lib/WorldOfAnime/SchemaClass/Result/LinksLinks.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/LinksLinks.pm \
	lib/WorldOfAnime/Controller/Moderate.pm \
	blib/lib/WorldOfAnime/Controller/Moderate.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryRatings.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryRatings.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBChangeTypes.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBChangeTypes.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImageComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImageComments.pm \
	lib/WorldOfAnime/Controller/Groups.pm \
	blib/lib/WorldOfAnime/Controller/Groups.pm \
	lib/WorldOfAnime/Model/Groups/GroupMembers.pm \
	blib/lib/WorldOfAnime/Model/Groups/GroupMembers.pm \
	lib/WorldOfAnime/Model/URL.pm \
	blib/lib/WorldOfAnime/Model/URL.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBGenres.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBGenres.pm \
	lib/WorldOfAnime/Controller/ArtStory.pm \
	blib/lib/WorldOfAnime/Controller/ArtStory.pm \
	lib/WorldOfAnime/Controller/Chat.pm \
	blib/lib/WorldOfAnime/Controller/Chat.pm \
	lib/WorldOfAnime/SchemaClass/Result/BlogUserSubscriptions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/BlogUserSubscriptions.pm \
	lib/WorldOfAnime/Model/Messages/Thread.pm \
	blib/lib/WorldOfAnime/Model/Messages/Thread.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImages.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImages.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserFavoriteAnime.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserFavoriteAnime.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserProfile.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserProfile.pm \
	lib/WorldOfAnime/SchemaClass/Result/BlogComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/BlogComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/StagingEmails.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/StagingEmails.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBRatings.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBRatings.pm \
	lib/WorldOfAnime/SchemaClass/Result/AdSizes.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/AdSizes.pm \
	lib/WorldOfAnime/Model/Images.pm \
	blib/lib/WorldOfAnime/Model/Images.pm \
	CreateStagedEmails.pl \
	$(INST_LIB)/CreateStagedEmails.pl \
	lib/WorldOfAnime/SchemaClass/Result/UserFavoriteMovies.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserFavoriteMovies.pm \
	lib/WorldOfAnime/View/Plain.pm \
	blib/lib/WorldOfAnime/View/Plain.pm \
	lib/WorldOfAnime/Controller/DAO_Anime.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Anime.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserStatuses.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserStatuses.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryChapter.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryChapter.pm \
	lib/WorldOfAnime/View/JSON.pm \
	blib/lib/WorldOfAnime/View/JSON.pm \
	lib/WorldOfAnime.pm \
	blib/lib/WorldOfAnime.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupUsers.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupUsers.pm \
	lib/WorldOfAnime/SchemaClass/Result/Stats.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Stats.pm \
	lib/WorldOfAnime/Model/AnimeCacheable.pm \
	blib/lib/WorldOfAnime/Model/AnimeCacheable.pm \
	lib/WorldOfAnime/Controller/Image.pm \
	blib/lib/WorldOfAnime/Controller/Image.pm \
	lib/WorldOfAnime/Controller/DAO_Searches.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Searches.pm \
	lib/WorldOfAnime/SchemaClass/Result/ThreadPosts.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ThreadPosts.pm \
	lib/WorldOfAnime/SchemaClass/Result/GameCategories.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GameCategories.pm \
	lib/WorldOfAnime/Model/Comments/ProfileComment.pm \
	blib/lib/WorldOfAnime/Model/Comments/ProfileComment.pm \
	lib/WorldOfAnime/Controller/DAO_Friends.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Friends.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitlesEpisodes.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBTitlesEpisodes.pm \
	lib/WorldOfAnime/Controller/Links.pm \
	blib/lib/WorldOfAnime/Controller/Links.pm \
	lib/WorldOfAnime/SchemaClass/Result/ChatMessages.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ChatMessages.pm \
	lib/WorldOfAnime/SchemaClass/Result/GalleryImages.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GalleryImages.pm \
	lib/WorldOfAnime/SchemaClass/Result/GamePlays.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GamePlays.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupCommentReplies.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupCommentReplies.pm \
	lib/WorldOfAnime/Model/Comments/Comment.pm \
	blib/lib/WorldOfAnime/Model/Comments/Comment.pm \
	lib/WorldOfAnime/SchemaClass/Result/PollChoices.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/PollChoices.pm \
	lib/WorldOfAnime/SchemaClass/Result/GalleryImageComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GalleryImageComments.pm \
	lib/WorldOfAnime/Model/Groups/Group.pm \
	blib/lib/WorldOfAnime/Model/Groups/Group.pm \
	lib/WorldOfAnime/SchemaClass.pm \
	blib/lib/WorldOfAnime/SchemaClass.pm \
	lib/WorldOfAnime/Controller/ImageTags.pm \
	blib/lib/WorldOfAnime/Controller/ImageTags.pm \
	lib/WorldOfAnime/SchemaClass/Result/AnimeTitles.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/AnimeTitles.pm \
	lib/WorldOfAnime/SchemaClass/Result/EmailSuppression.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/EmailSuppression.pm \
	lib/WorldOfAnime/Controller/Games.pm \
	blib/lib/WorldOfAnime/Controller/Games.pm \
	lib/WorldOfAnime/Controller/DAO_News.pm \
	blib/lib/WorldOfAnime/Controller/DAO_News.pm \
	lib/WorldOfAnime/Controller/News.pm \
	blib/lib/WorldOfAnime/Controller/News.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStorySubscriptions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ArtStorySubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryTitle.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryTitle.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitleReviewComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBTitleReviewComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupInvites.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupInvites.pm \
	lib/WorldOfAnime/SchemaClass/Result/MovieTitles.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/MovieTitles.pm \
	lib/WorldOfAnime/Controller/DAO_Tags.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Tags.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupComments.pm \
	lib/WorldOfAnime/Controller/DAO_Format.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Format.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupGalleries.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupGalleries.pm \
	lib/WorldOfAnime/SchemaClass/Result/GameFavorites.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GameFavorites.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitles.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBTitles.pm \
	lib/WorldOfAnime/SchemaClass/Result/Images.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Images.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumThreads.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ForumThreads.pm \
	lib/WorldOfAnime/SchemaClass/Result/LastAction.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/LastAction.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserFriends.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserFriends.pm \
	lib/WorldOfAnime/Model/Galleries/Gallery.pm \
	blib/lib/WorldOfAnime/Model/Galleries/Gallery.pm \
	lib/WorldOfAnime/SchemaClass/Result/QAAnswers.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/QAAnswers.pm \
	lib/WorldOfAnime/SchemaClass/Result/AdAffiliates.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/AdAffiliates.pm \
	lib/WorldOfAnime/Model/Reviews/AnimeReview.pm \
	blib/lib/WorldOfAnime/Model/Reviews/AnimeReview.pm \
	lib/WorldOfAnime/Controller/Forums.pm \
	blib/lib/WorldOfAnime/Controller/Forums.pm \
	lib/WorldOfAnime/Controller/Search.pm \
	blib/lib/WorldOfAnime/Controller/Search.pm \
	lib/WorldOfAnime/SchemaClass/Result/Blogs.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Blogs.pm \
	lib/WorldOfAnime/SchemaClass/Result/Roles.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Roles.pm \
	lib/WorldOfAnime/Model/Art/Story.pm \
	blib/lib/WorldOfAnime/Model/Art/Story.pm \
	lib/WorldOfAnime/Model/Messages/UserMessages.pm \
	blib/lib/WorldOfAnime/Model/Messages/UserMessages.pm \
	lib/WorldOfAnime/Controller/ImageGalleries.pm \
	blib/lib/WorldOfAnime/Controller/ImageGalleries.pm \
	lib/WorldOfAnime/Controller/Favorites.pm \
	blib/lib/WorldOfAnime/Controller/Favorites.pm \
	lib/WorldOfAnime/Controller/Profile.pm \
	blib/lib/WorldOfAnime/Controller/Profile.pm \
	lib/WorldOfAnime/SchemaClass/Result/SearchesGeneric.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/SearchesGeneric.pm \
	lib/WorldOfAnime/SchemaClass/Result/Groups.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Groups.pm \
	lib/WorldOfAnime/SchemaClass/Result/Ads.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Ads.pm \
	lib/WorldOfAnime/Model/S3.pm \
	blib/lib/WorldOfAnime/Model/S3.pm \
	lib/WorldOfAnime/SchemaClass/Result/ArtStoryComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryComments.pm \
	lib/WorldOfAnime/SchemaClass/Result/NewsArticleComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/NewsArticleComments.pm \
	lib/WorldOfAnime/Controller/Admin.pm \
	blib/lib/WorldOfAnime/Controller/Admin.pm \
	lib/WorldOfAnime/Controller/DAO_ArtStory.pm \
	blib/lib/WorldOfAnime/Controller/DAO_ArtStory.pm \
	scratch.pm \
	$(INST_LIB)/scratch.pm \
	lib/WorldOfAnime/Controller/DAO_Messages.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Messages.pm \
	lib/WorldOfAnime/View/HTML.pm \
	blib/lib/WorldOfAnime/View/HTML.pm \
	lib/WorldOfAnime/SchemaClass/Result/Logins.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Logins.pm \
	lib/WorldOfAnime/SchemaClass/Result/Sessions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Sessions.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitleReviews.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBTitleReviews.pm \
	lib/WorldOfAnime/Model/Polls/PollChoices.pm \
	blib/lib/WorldOfAnime/Model/Polls/PollChoices.pm \
	lib/WorldOfAnime/Controller/DAO_Favorites.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Favorites.pm \
	lib/WorldOfAnime/Controller/Anime.pm \
	blib/lib/WorldOfAnime/Controller/Anime.pm \
	lib/WorldOfAnime/Controller/DAO_Forums.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Forums.pm \
	lib/WorldOfAnime/Model/Formatter.pm \
	blib/lib/WorldOfAnime/Model/Formatter.pm \
	lib/WorldOfAnime/SchemaClass/Result/Users.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Users.pm \
	lib/WorldOfAnime/Model/Messages/PrivateMessage.pm \
	blib/lib/WorldOfAnime/Model/Messages/PrivateMessage.pm \
	lib/WorldOfAnime/Model/Polls/Poll.pm \
	blib/lib/WorldOfAnime/Model/Polls/Poll.pm \
	lib/WorldOfAnime/Controller/DAO_Games.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Games.pm \
	lib/WorldOfAnime/Model/Users/UserProfileAppearance.pm \
	blib/lib/WorldOfAnime/Model/Users/UserProfileAppearance.pm \
	lib/WorldOfAnime/SchemaClass/Result/StagingNotifications.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/StagingNotifications.pm \
	lib/WorldOfAnime/SchemaClass/Result/GamesInCategories.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GamesInCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupJoinRequests.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupJoinRequests.pm \
	lib/WorldOfAnime/SchemaClass/Result/FavoritesGalleryImages.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/FavoritesGalleryImages.pm \
	lib/WorldOfAnime/Controller/Notifications.pm \
	blib/lib/WorldOfAnime/Controller/Notifications.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBTitlesToGenres.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBTitlesToGenres.pm \
	lib/WorldOfAnime/Model/Images/Image.pm \
	blib/lib/WorldOfAnime/Model/Images/Image.pm \
	lib/WorldOfAnime/SchemaClass/Result/NewsArticles.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/NewsArticles.pm \
	lib/WorldOfAnime/Model/Galleries/UserGalleries.pm \
	blib/lib/WorldOfAnime/Model/Galleries/UserGalleries.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBChanges.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBChanges.pm \
	lib/WorldOfAnime/SchemaClass/Result/Galleries.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Galleries.pm \
	lib/WorldOfAnime/Controller/Root.pm \
	blib/lib/WorldOfAnime/Controller/Root.pm \
	lib/WorldOfAnime/SchemaClass/Result/BlogSubscriptions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/BlogSubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumCategories.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ForumCategories.pm \
	lib/WorldOfAnime/Controller/Tags.pm \
	blib/lib/WorldOfAnime/Controller/Tags.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserComments.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserComments.pm \
	lib/WorldOfAnime/Controller/QA.pm \
	blib/lib/WorldOfAnime/Controller/QA.pm \
	lib/WorldOfAnime/Model/Images/GalleryImage.pm \
	blib/lib/WorldOfAnime/Model/Images/GalleryImage.pm \
	SendWaitingEmailsHTML.pl \
	$(INST_LIB)/SendWaitingEmailsHTML.pl \
	lib/WorldOfAnime/SchemaClass/Result/PollQuestions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/PollQuestions.pm \
	lib/WorldOfAnime/SchemaClass/Result/PrivateMessages.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/PrivateMessages.pm \
	lib/WorldOfAnime/SchemaClass/Result/GalleryImagesToTags.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GalleryImagesToTags.pm \
	lib/WorldOfAnime/SchemaClass/Result/DBCategories.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/DBCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/Searches.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Searches.pm \
	lib/WorldOfAnime/SchemaClass/Result/Games.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Games.pm \
	lib/WorldOfAnime/Model/DB.pm \
	blib/lib/WorldOfAnime/Model/DB.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumThreadSubscriptions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ForumThreadSubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/ForumForums.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ForumForums.pm \
	lib/WorldOfAnime/SchemaClass/Result/UsersToRoles.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UsersToRoles.pm \
	lib/WorldOfAnime/SchemaClass/Result/QAQuestions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/QAQuestions.pm \
	lib/WorldOfAnime/SchemaClass/Result/Notifications.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Notifications.pm \
	lib/WorldOfAnime/Model/Users/UserProfile.pm \
	blib/lib/WorldOfAnime/Model/Users/UserProfile.pm \
	lib/WorldOfAnime/SchemaClass/Result/EmailTemplates.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/EmailTemplates.pm \
	lib/WorldOfAnime/Controller/Email.pm \
	blib/lib/WorldOfAnime/Controller/Email.pm \
	lib/WorldOfAnime/SchemaClass/Result/LinksCategories.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/LinksCategories.pm \
	lib/WorldOfAnime/SchemaClass/Result/Referrals.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Referrals.pm \
	lib/WorldOfAnime/SchemaClass/Result/QASubscriptions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/QASubscriptions.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserActions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserActions.pm \
	lib/WorldOfAnime/SchemaClass/Result/GroupLogs.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/GroupLogs.pm \
	lib/WorldOfAnime/Controller/DAO_Comments.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Comments.pm \
	lib/WorldOfAnime/Controller/Messages.pm \
	blib/lib/WorldOfAnime/Controller/Messages.pm \
	lib/WorldOfAnime/Controller/DAO_ImageTags.pm \
	blib/lib/WorldOfAnime/Controller/DAO_ImageTags.pm \
	lib/WorldOfAnime/SchemaClass/Result/Actions.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Actions.pm \
	lib/WorldOfAnime/Model/Users/User.pm \
	blib/lib/WorldOfAnime/Model/Users/User.pm \
	lib/WorldOfAnime/SchemaClass/Result/Tags.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Tags.pm \
	lib/WorldOfAnime/Controller/Polls.pm \
	blib/lib/WorldOfAnime/Controller/Polls.pm \
	lib/WorldOfAnime/Model/Art/StoryChapter.pm \
	blib/lib/WorldOfAnime/Model/Art/StoryChapter.pm \
	lib/WorldOfAnime/Controller/Users.pm \
	blib/lib/WorldOfAnime/Controller/Users.pm \
	lib/WorldOfAnime/Model/Reviews/Review.pm \
	blib/lib/WorldOfAnime/Model/Reviews/Review.pm \
	lib/WorldOfAnime/SchemaClass/Result/UserProfileSiteNotifications.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/UserProfileSiteNotifications.pm \
	lib/WorldOfAnime/SchemaClass/Result/ChatUsers.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/ChatUsers.pm \
	lib/WorldOfAnime/Controller/DAO_Images.pm \
	blib/lib/WorldOfAnime/Controller/DAO_Images.pm \
	lib/WorldOfAnime/SchemaClass/Result/Timezones.pm \
	blib/lib/WorldOfAnime/SchemaClass/Result/Timezones.pm


# --- MakeMaker platform_constants section:
MM_Unix_VERSION = 6.64
PERL_MALLOC_DEF = -DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc -Dfree=Perl_mfree -Drealloc=Perl_realloc -Dcalloc=Perl_calloc


# --- MakeMaker tool_autosplit section:
# Usage: $(AUTOSPLITFILE) FileToSplit AutoDirToSplitInto
AUTOSPLITFILE = $(ABSPERLRUN)  -e 'use AutoSplit;  autosplit($$$$ARGV[0], $$$$ARGV[1], 0, 1, 1)' --



# --- MakeMaker tool_xsubpp section:


# --- MakeMaker tools_other section:
SHELL = /bin/sh
CHMOD = chmod
CP = cp
MV = mv
NOOP = $(TRUE)
NOECHO = @
RM_F = rm -f
RM_RF = rm -rf
TEST_F = test -f
TOUCH = touch
UMASK_NULL = umask 0
DEV_NULL = > /dev/null 2>&1
MKPATH = $(ABSPERLRUN) -MExtUtils::Command -e 'mkpath' --
EQUALIZE_TIMESTAMP = $(ABSPERLRUN) -MExtUtils::Command -e 'eqtime' --
FALSE = false
TRUE = true
ECHO = echo
ECHO_N = echo -n
UNINST = 0
VERBINST = 0
MOD_INSTALL = $(ABSPERLRUN) -MExtUtils::Install -e 'install([ from_to => {@ARGV}, verbose => '\''$(VERBINST)'\'', uninstall_shadows => '\''$(UNINST)'\'', dir_mode => '\''$(PERM_DIR)'\'' ]);' --
DOC_INSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'perllocal_install' --
UNINSTALL = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'uninstall' --
WARN_IF_OLD_PACKLIST = $(ABSPERLRUN) -MExtUtils::Command::MM -e 'warn_if_old_packlist' --
MACROSTART = 
MACROEND = 
USEMAKEFILE = -f
FIXIN = $(ABSPERLRUN) -MExtUtils::MY -e 'MY->fixin(shift)' --


# --- MakeMaker makemakerdflt section:
makemakerdflt : all
	$(NOECHO) $(NOOP)


# --- MakeMaker dist section:
TAR = tar
TARFLAGS = cvf
ZIP = zip
ZIPFLAGS = -r
COMPRESS = gzip --best
SUFFIX = .gz
SHAR = shar
PREOP = $(PERL) -I. "-MModule::Install::Admin" -e "dist_preop(q($(DISTVNAME)))"
POSTOP = $(NOECHO) $(NOOP)
TO_UNIX = $(NOECHO) $(NOOP)
CI = ci -u
RCS_LABEL = rcs -Nv$(VERSION_SYM): -q
DIST_CP = best
DIST_DEFAULT = tardist
DISTNAME = WorldOfAnime
DISTVNAME = WorldOfAnime-1.0


# --- MakeMaker macro section:


# --- MakeMaker depend section:


# --- MakeMaker cflags section:


# --- MakeMaker const_loadlibs section:


# --- MakeMaker const_cccmd section:


# --- MakeMaker post_constants section:


# --- MakeMaker pasthru section:

PASTHRU = LIBPERL_A="$(LIBPERL_A)"\
	LINKTYPE="$(LINKTYPE)"\
	PREFIX="$(PREFIX)"


# --- MakeMaker special_targets section:
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir



# --- MakeMaker c_o section:


# --- MakeMaker xs_c section:


# --- MakeMaker xs_o section:


# --- MakeMaker top_targets section:
all :: pure_all manifypods
	$(NOECHO) $(NOOP)


pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)

help :
	perldoc ExtUtils::MakeMaker


# --- MakeMaker blibdirs section:
blibdirs : $(INST_LIBDIR)$(DFSEP).exists $(INST_ARCHLIB)$(DFSEP).exists $(INST_AUTODIR)$(DFSEP).exists $(INST_ARCHAUTODIR)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists $(INST_SCRIPT)$(DFSEP).exists $(INST_MAN1DIR)$(DFSEP).exists $(INST_MAN3DIR)$(DFSEP).exists
	$(NOECHO) $(NOOP)

# Backwards compat with 6.18 through 6.25
blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

$(INST_LIBDIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_LIBDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_LIBDIR)
	$(NOECHO) $(TOUCH) $(INST_LIBDIR)$(DFSEP).exists

$(INST_ARCHLIB)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHLIB)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHLIB)
	$(NOECHO) $(TOUCH) $(INST_ARCHLIB)$(DFSEP).exists

$(INST_AUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_AUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_AUTODIR)
	$(NOECHO) $(TOUCH) $(INST_AUTODIR)$(DFSEP).exists

$(INST_ARCHAUTODIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_ARCHAUTODIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_ARCHAUTODIR)
	$(NOECHO) $(TOUCH) $(INST_ARCHAUTODIR)$(DFSEP).exists

$(INST_BIN)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_BIN)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_BIN)
	$(NOECHO) $(TOUCH) $(INST_BIN)$(DFSEP).exists

$(INST_SCRIPT)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_SCRIPT)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_SCRIPT)
	$(NOECHO) $(TOUCH) $(INST_SCRIPT)$(DFSEP).exists

$(INST_MAN1DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN1DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN1DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN1DIR)$(DFSEP).exists

$(INST_MAN3DIR)$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) $(INST_MAN3DIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(INST_MAN3DIR)
	$(NOECHO) $(TOUCH) $(INST_MAN3DIR)$(DFSEP).exists



# --- MakeMaker linkext section:

linkext :: $(LINKTYPE)
	$(NOECHO) $(NOOP)


# --- MakeMaker dlsyms section:


# --- MakeMaker dynamic section:

dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)


# --- MakeMaker dynamic_bs section:

BOOTSTRAP =


# --- MakeMaker dynamic_lib section:


# --- MakeMaker static section:

## $(INST_PM) has been moved to the all: target.
## It remains here for awhile to allow for old usage: "make static"
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)


# --- MakeMaker static_lib section:


# --- MakeMaker manifypods section:

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all  \
	script/worldofanime_fastcgi.pl \
	script/worldofanime_create.pl \
	script/worldofanime_cgi.pl \
	script/worldofanime_test.pl \
	script/worldofanime_server.pl \
	lib/WorldOfAnime/Model/AnimeCacheable.pm \
	lib/WorldOfAnime/View/HTML.pm \
	lib/WorldOfAnime/Model/Images.pm \
	lib/WorldOfAnime/Controller/DAO_Forums.pm \
	lib/WorldOfAnime/Model/DB.pm \
	lib/WorldOfAnime/View/JSON.pm \
	lib/WorldOfAnime/Model/Anime.pm
	$(NOECHO) $(POD2MAN) --section=1 --perm_rw=$(PERM_RW) \
	  script/worldofanime_fastcgi.pl $(INST_MAN1DIR)/worldofanime_fastcgi.pl.$(MAN1EXT) \
	  script/worldofanime_create.pl $(INST_MAN1DIR)/worldofanime_create.pl.$(MAN1EXT) \
	  script/worldofanime_cgi.pl $(INST_MAN1DIR)/worldofanime_cgi.pl.$(MAN1EXT) \
	  script/worldofanime_test.pl $(INST_MAN1DIR)/worldofanime_test.pl.$(MAN1EXT) \
	  script/worldofanime_server.pl $(INST_MAN1DIR)/worldofanime_server.pl.$(MAN1EXT) 
	$(NOECHO) $(POD2MAN) --section=3 --perm_rw=$(PERM_RW) \
	  lib/WorldOfAnime/Model/AnimeCacheable.pm $(INST_MAN3DIR)/WorldOfAnime::Model::AnimeCacheable.$(MAN3EXT) \
	  lib/WorldOfAnime/View/HTML.pm $(INST_MAN3DIR)/WorldOfAnime::View::HTML.$(MAN3EXT) \
	  lib/WorldOfAnime/Model/Images.pm $(INST_MAN3DIR)/WorldOfAnime::Model::Images.$(MAN3EXT) \
	  lib/WorldOfAnime/Controller/DAO_Forums.pm $(INST_MAN3DIR)/WorldOfAnime::Controller::DAO_Forums.$(MAN3EXT) \
	  lib/WorldOfAnime/Model/DB.pm $(INST_MAN3DIR)/WorldOfAnime::Model::DB.$(MAN3EXT) \
	  lib/WorldOfAnime/View/JSON.pm $(INST_MAN3DIR)/WorldOfAnime::View::JSON.$(MAN3EXT) \
	  lib/WorldOfAnime/Model/Anime.pm $(INST_MAN3DIR)/WorldOfAnime::Model::Anime.$(MAN3EXT) 




# --- MakeMaker processPL section:


# --- MakeMaker installbin section:

EXE_FILES = script/worldofanime_cgi.pl script/worldofanime_create.pl script/worldofanime_fastcgi.pl script/worldofanime_server.pl script/worldofanime_test.pl

pure_all :: $(INST_SCRIPT)/worldofanime_fastcgi.pl $(INST_SCRIPT)/worldofanime_create.pl $(INST_SCRIPT)/worldofanime_cgi.pl $(INST_SCRIPT)/worldofanime_test.pl $(INST_SCRIPT)/worldofanime_server.pl
	$(NOECHO) $(NOOP)

realclean ::
	$(RM_F) \
	  $(INST_SCRIPT)/worldofanime_fastcgi.pl $(INST_SCRIPT)/worldofanime_create.pl \
	  $(INST_SCRIPT)/worldofanime_cgi.pl $(INST_SCRIPT)/worldofanime_test.pl \
	  $(INST_SCRIPT)/worldofanime_server.pl 

$(INST_SCRIPT)/worldofanime_fastcgi.pl : script/worldofanime_fastcgi.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/worldofanime_fastcgi.pl
	$(CP) script/worldofanime_fastcgi.pl $(INST_SCRIPT)/worldofanime_fastcgi.pl
	$(FIXIN) $(INST_SCRIPT)/worldofanime_fastcgi.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/worldofanime_fastcgi.pl

$(INST_SCRIPT)/worldofanime_create.pl : script/worldofanime_create.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/worldofanime_create.pl
	$(CP) script/worldofanime_create.pl $(INST_SCRIPT)/worldofanime_create.pl
	$(FIXIN) $(INST_SCRIPT)/worldofanime_create.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/worldofanime_create.pl

$(INST_SCRIPT)/worldofanime_cgi.pl : script/worldofanime_cgi.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/worldofanime_cgi.pl
	$(CP) script/worldofanime_cgi.pl $(INST_SCRIPT)/worldofanime_cgi.pl
	$(FIXIN) $(INST_SCRIPT)/worldofanime_cgi.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/worldofanime_cgi.pl

$(INST_SCRIPT)/worldofanime_test.pl : script/worldofanime_test.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/worldofanime_test.pl
	$(CP) script/worldofanime_test.pl $(INST_SCRIPT)/worldofanime_test.pl
	$(FIXIN) $(INST_SCRIPT)/worldofanime_test.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/worldofanime_test.pl

$(INST_SCRIPT)/worldofanime_server.pl : script/worldofanime_server.pl $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) $(INST_SCRIPT)/worldofanime_server.pl
	$(CP) script/worldofanime_server.pl $(INST_SCRIPT)/worldofanime_server.pl
	$(FIXIN) $(INST_SCRIPT)/worldofanime_server.pl
	-$(NOECHO) $(CHMOD) $(PERM_RWX) $(INST_SCRIPT)/worldofanime_server.pl



# --- MakeMaker subdirs section:

# none

# --- MakeMaker clean_subdirs section:
clean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean :: clean_subdirs
	- $(RM_F) \
	  *$(LIB_EXT) core \
	  core.[0-9] $(INST_ARCHAUTODIR)/extralibs.all \
	  core.[0-9][0-9] $(BASEEXT).bso \
	  pm_to_blib.ts MYMETA.json \
	  core.[0-9][0-9][0-9][0-9] MYMETA.yml \
	  $(BASEEXT).x $(BOOTSTRAP) \
	  perl$(EXE_EXT) tmon.out \
	  *$(OBJ_EXT) pm_to_blib \
	  $(INST_ARCHAUTODIR)/extralibs.ld blibdirs.ts \
	  core.[0-9][0-9][0-9][0-9][0-9] *perl.core \
	  core.*perl.*.? $(MAKE_APERL_FILE) \
	  $(BASEEXT).def perl \
	  core.[0-9][0-9][0-9] mon.out \
	  lib$(BASEEXT).def perlmain.c \
	  perl.exe so_locations \
	  $(BASEEXT).exp 
	- $(RM_RF) \
	  blib 
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)


# --- MakeMaker realclean_subdirs section:
realclean_subdirs :
	$(NOECHO) $(NOOP)


# --- MakeMaker realclean section:
# Delete temporary files (via clean) and also delete dist files
realclean purge ::  clean realclean_subdirs
	- $(RM_F) \
	  $(MAKEFILE_OLD) $(FIRST_MAKEFILE) 
	- $(RM_RF) \
	  MYMETA.yml $(DISTVNAME) 


# --- MakeMaker metafile section:
metafile :
	$(NOECHO) $(NOOP)


# --- MakeMaker signature section:
signature :
	cpansign -s


# --- MakeMaker dist_basics section:
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old 



# --- MakeMaker dist_core section:

dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) $(ABSPERLRUN) -l -e 'print '\''Warning: Makefile possibly out of date with $(VERSION_FROM)'\''' \
	  -e '    if -e '\''$(VERSION_FROM)'\'' and -M '\''$(VERSION_FROM)'\'' < -M '\''$(FIRST_MAKEFILE)'\'';' --

tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)

uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu

$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)

zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)

$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)

shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)


# --- MakeMaker distdir section:
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir  
	$(NOECHO) $(NOOP)



# --- MakeMaker dist_test section:
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)



# --- MakeMaker dist_ci section:

ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \
	  -e "@all = keys %{ maniread() };" \
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"


# --- MakeMaker distmeta section:
distmeta : create_distdir metafile
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -e q{META.yml};' \
	  -e 'eval { maniadd({q{META.yml} => q{Module YAML meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.yml to MANIFEST: $$$${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'exit unless -f q{META.json};' \
	  -e 'eval { maniadd({q{META.json} => q{Module JSON meta-data (added by MakeMaker)}}) }' \
	  -e '    or print "Could not add META.json to MANIFEST: $$$${'\''@'\''}\n"' --



# --- MakeMaker distsignature section:
distsignature : create_distdir
	$(NOECHO) cd $(DISTVNAME) && $(ABSPERLRUN) -MExtUtils::Manifest=maniadd -e 'eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) } ' \
	  -e '    or print "Could not add SIGNATURE to MANIFEST: $$$${'\''@'\''}\n"' --
	$(NOECHO) cd $(DISTVNAME) && $(TOUCH) SIGNATURE
	cd $(DISTVNAME) && cpansign -s



# --- MakeMaker install section:

install :: pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLARCHLIB)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(SITEARCHEXP)/auto/$(FULLEXT)


pure_site_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLSITEARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSITESCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		$(PERL_ARCHLIB)/auto/$(FULLEXT)

pure_vendor_install :: all
	$(NOECHO) $(MOD_INSTALL) \
		read $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist \
		write $(DESTINSTALLVENDORARCH)/auto/$(FULLEXT)/.packlist \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLVENDORSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_site_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod

doc_vendor_install :: all
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> $(DESTINSTALLARCHLIB)/perllocal.pod


uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) $(PERL_ARCHLIB)/auto/$(FULLEXT)/.packlist

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) $(SITEARCHEXP)/auto/$(FULLEXT)/.packlist

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) $(VENDORARCHEXP)/auto/$(FULLEXT)/.packlist


# --- MakeMaker force section:
# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)


# --- MakeMaker perldepend section:


# --- MakeMaker makefile section:
# We take a very conservative approach here, but it's worth it.
# We move Makefile to Makefile.old here to avoid gnu make looping.
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to $?"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL 
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	$(FALSE)



# --- MakeMaker staticmake section:

# --- MakeMaker makeaperl section ---
MAP_TARGET    = perl
FULLPERL      = /usr/bin/perl

$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR= \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=


# --- MakeMaker test section:

TEST_VERBOSE=0
TEST_TYPE=test_$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = t/01app.t t/02pod.t t/03podcoverage.t t/controller_Anime.t t/controller_ArtStory.t t/controller_DAO_Anime.t t/controller_DAO_ArtStory.t t/controller_DAO_Blogs.t t/controller_DAO_Comments.t t/controller_DAO_Favorites.t t/controller_DAO_Format.t t/controller_DAO_Forums.t t/controller_DAO_Friends.t t/controller_DAO_Games.t t/controller_DAO_Groups.t t/controller_DAO_ImageTags.t t/controller_DAO_Messages.t t/controller_DAO_News.t t/controller_DAO_Searches.t t/controller_DAO_Tags.t t/controller_Favorites.t t/controller_Forums.t t/controller_Games.t t/controller_Image.t t/controller_ImageGalleries.t t/controller_ImageTags.t t/controller_Messages.t t/controller_Moderate.t t/controller_News.t t/controller_Polls.t t/controller_Profile.t t/controller_Tags.t t/controller_Users.t t/model_Anime.t t/model_DB.t t/model_Galleries-Gallery.t t/model_Galleries-UserGalleries.t t/model_Gallery-UserGalleries.t t/model_Images-GalleryImage.t t/model_Images-Image.t t/model_Messages-PrivateMessage.t t/model_Messages-Thread.t t/model_Messages-UserMessages.t t/model_Polls-PollChoices.t t/model_Polls-Polls.t t/model_Session.t t/model_Users-UserEmailNotifications.t t/model_Users.t t/view_Email.t t/view_JSON.t t/view_Thumbnail.t
TESTDB_SW = -d

testdb :: testdb_$(LINKTYPE)

test :: $(TEST_TYPE) subdirs-test

subdirs-test ::
	$(NOECHO) $(NOOP)


test_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) "-MExtUtils::Command::MM" "-e" "test_harness($(TEST_VERBOSE), 'inc', '$(INST_LIB)', '$(INST_ARCHLIB)')" $(TEST_FILES)

testdb_dynamic :: pure_all
	PERL_DL_NONLAZY=1 $(FULLPERLRUN) $(TESTDB_SW) "-Iinc" "-I$(INST_LIB)" "-I$(INST_ARCHLIB)" $(TEST_FILE)

test_ : test_dynamic

test_static :: test_dynamic
testdb_static :: testdb_dynamic


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd :
	$(NOECHO) $(ECHO) '<SOFTPKG NAME="$(DISTNAME)" VERSION="$(VERSION)">' > $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <ABSTRACT></ABSTRACT>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <AUTHOR></AUTHOR>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    <IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Catalyst::Action::RenderView" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Catalyst::Plugin::ConfigLoader" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Catalyst::Plugin::Static::Simple" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Catalyst::Runtime" VERSION="5.80007" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="Config::General" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <REQUIRE NAME="parent::" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <ARCHITECTURE NAME="x86_64-linux-gnu-thread-multi-5.10" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '        <CODEBASE HREF="" />' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '    </IMPLEMENTATION>' >> $(DISTNAME).ppd
	$(NOECHO) $(ECHO) '</SOFTPKG>' >> $(DISTNAME).ppd


# --- MakeMaker pm_to_blib section:

pm_to_blib : $(FIRST_MAKEFILE) $(TO_INST_PM)
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/WorldOfAnime/Controller/Blogs.pm blib/lib/WorldOfAnime/Controller/Blogs.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Emails.pm blib/lib/WorldOfAnime/SchemaClass/Result/Emails.pm \
	  lib/WorldOfAnime/Controller/DAO_Users.pm blib/lib/WorldOfAnime/Controller/DAO_Users.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UserBlocks.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserBlocks.pm \
	  lib/WorldOfAnime/Model/Database/Title.pm blib/lib/WorldOfAnime/Model/Database/Title.pm \
	  lib/WorldOfAnime/Controller/Chat.pm.old blib/lib/WorldOfAnime/Controller/Chat.pm.old \
	  lib/WorldOfAnime/Controller/DAO_Email.pm blib/lib/WorldOfAnime/Controller/DAO_Email.pm \
	  lib/WorldOfAnime/Controller/DAO_Groups.pm blib/lib/WorldOfAnime/Controller/DAO_Groups.pm \
	  lib/WorldOfAnime/Model/Anime.pm blib/lib/WorldOfAnime/Model/Anime.pm \
	  lib/WorldOfAnime/Controller/DAO_Blogs.pm blib/lib/WorldOfAnime/Controller/DAO_Blogs.pm \
	  lib/WorldOfAnime/Model/Database/AnimeTitle.pm blib/lib/WorldOfAnime/Model/Database/AnimeTitle.pm \
	  lib/WorldOfAnime/SchemaClass/Result/LinksLinks.pm blib/lib/WorldOfAnime/SchemaClass/Result/LinksLinks.pm \
	  lib/WorldOfAnime/Controller/Moderate.pm blib/lib/WorldOfAnime/Controller/Moderate.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ArtStoryRatings.pm blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryRatings.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBChangeTypes.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBChangeTypes.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImageComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImageComments.pm \
	  lib/WorldOfAnime/Controller/Groups.pm blib/lib/WorldOfAnime/Controller/Groups.pm \
	  lib/WorldOfAnime/Model/Groups/GroupMembers.pm blib/lib/WorldOfAnime/Model/Groups/GroupMembers.pm \
	  lib/WorldOfAnime/Model/URL.pm blib/lib/WorldOfAnime/Model/URL.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBGenres.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBGenres.pm \
	  lib/WorldOfAnime/Controller/ArtStory.pm blib/lib/WorldOfAnime/Controller/ArtStory.pm \
	  lib/WorldOfAnime/Controller/Chat.pm blib/lib/WorldOfAnime/Controller/Chat.pm \
	  lib/WorldOfAnime/SchemaClass/Result/BlogUserSubscriptions.pm blib/lib/WorldOfAnime/SchemaClass/Result/BlogUserSubscriptions.pm \
	  lib/WorldOfAnime/Model/Messages/Thread.pm blib/lib/WorldOfAnime/Model/Messages/Thread.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImages.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupGalleryImages.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UserFavoriteAnime.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserFavoriteAnime.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UserProfile.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserProfile.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/WorldOfAnime/SchemaClass/Result/BlogComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/BlogComments.pm \
	  lib/WorldOfAnime/SchemaClass/Result/StagingEmails.pm blib/lib/WorldOfAnime/SchemaClass/Result/StagingEmails.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBRatings.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBRatings.pm \
	  lib/WorldOfAnime/SchemaClass/Result/AdSizes.pm blib/lib/WorldOfAnime/SchemaClass/Result/AdSizes.pm \
	  lib/WorldOfAnime/Model/Images.pm blib/lib/WorldOfAnime/Model/Images.pm \
	  CreateStagedEmails.pl $(INST_LIB)/CreateStagedEmails.pl \
	  lib/WorldOfAnime/SchemaClass/Result/UserFavoriteMovies.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserFavoriteMovies.pm \
	  lib/WorldOfAnime/View/Plain.pm blib/lib/WorldOfAnime/View/Plain.pm \
	  lib/WorldOfAnime/Controller/DAO_Anime.pm blib/lib/WorldOfAnime/Controller/DAO_Anime.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UserStatuses.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserStatuses.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ArtStoryChapter.pm blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryChapter.pm \
	  lib/WorldOfAnime/View/JSON.pm blib/lib/WorldOfAnime/View/JSON.pm \
	  lib/WorldOfAnime.pm blib/lib/WorldOfAnime.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupUsers.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupUsers.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Stats.pm blib/lib/WorldOfAnime/SchemaClass/Result/Stats.pm \
	  lib/WorldOfAnime/Model/AnimeCacheable.pm blib/lib/WorldOfAnime/Model/AnimeCacheable.pm \
	  lib/WorldOfAnime/Controller/Image.pm blib/lib/WorldOfAnime/Controller/Image.pm \
	  lib/WorldOfAnime/Controller/DAO_Searches.pm blib/lib/WorldOfAnime/Controller/DAO_Searches.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ThreadPosts.pm blib/lib/WorldOfAnime/SchemaClass/Result/ThreadPosts.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GameCategories.pm blib/lib/WorldOfAnime/SchemaClass/Result/GameCategories.pm \
	  lib/WorldOfAnime/Model/Comments/ProfileComment.pm blib/lib/WorldOfAnime/Model/Comments/ProfileComment.pm \
	  lib/WorldOfAnime/Controller/DAO_Friends.pm blib/lib/WorldOfAnime/Controller/DAO_Friends.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBTitlesEpisodes.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBTitlesEpisodes.pm \
	  lib/WorldOfAnime/Controller/Links.pm blib/lib/WorldOfAnime/Controller/Links.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ChatMessages.pm blib/lib/WorldOfAnime/SchemaClass/Result/ChatMessages.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GalleryImages.pm blib/lib/WorldOfAnime/SchemaClass/Result/GalleryImages.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GamePlays.pm blib/lib/WorldOfAnime/SchemaClass/Result/GamePlays.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/WorldOfAnime/SchemaClass/Result/GroupCommentReplies.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupCommentReplies.pm \
	  lib/WorldOfAnime/Model/Comments/Comment.pm blib/lib/WorldOfAnime/Model/Comments/Comment.pm \
	  lib/WorldOfAnime/SchemaClass/Result/PollChoices.pm blib/lib/WorldOfAnime/SchemaClass/Result/PollChoices.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GalleryImageComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/GalleryImageComments.pm \
	  lib/WorldOfAnime/Model/Groups/Group.pm blib/lib/WorldOfAnime/Model/Groups/Group.pm \
	  lib/WorldOfAnime/SchemaClass.pm blib/lib/WorldOfAnime/SchemaClass.pm \
	  lib/WorldOfAnime/Controller/ImageTags.pm blib/lib/WorldOfAnime/Controller/ImageTags.pm \
	  lib/WorldOfAnime/SchemaClass/Result/AnimeTitles.pm blib/lib/WorldOfAnime/SchemaClass/Result/AnimeTitles.pm \
	  lib/WorldOfAnime/SchemaClass/Result/EmailSuppression.pm blib/lib/WorldOfAnime/SchemaClass/Result/EmailSuppression.pm \
	  lib/WorldOfAnime/Controller/Games.pm blib/lib/WorldOfAnime/Controller/Games.pm \
	  lib/WorldOfAnime/Controller/DAO_News.pm blib/lib/WorldOfAnime/Controller/DAO_News.pm \
	  lib/WorldOfAnime/Controller/News.pm blib/lib/WorldOfAnime/Controller/News.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ArtStorySubscriptions.pm blib/lib/WorldOfAnime/SchemaClass/Result/ArtStorySubscriptions.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ArtStoryTitle.pm blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryTitle.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBTitleReviewComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBTitleReviewComments.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupInvites.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupInvites.pm \
	  lib/WorldOfAnime/SchemaClass/Result/MovieTitles.pm blib/lib/WorldOfAnime/SchemaClass/Result/MovieTitles.pm \
	  lib/WorldOfAnime/Controller/DAO_Tags.pm blib/lib/WorldOfAnime/Controller/DAO_Tags.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupComments.pm \
	  lib/WorldOfAnime/Controller/DAO_Format.pm blib/lib/WorldOfAnime/Controller/DAO_Format.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupGalleries.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupGalleries.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GameFavorites.pm blib/lib/WorldOfAnime/SchemaClass/Result/GameFavorites.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBTitles.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBTitles.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Images.pm blib/lib/WorldOfAnime/SchemaClass/Result/Images.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ForumThreads.pm blib/lib/WorldOfAnime/SchemaClass/Result/ForumThreads.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/WorldOfAnime/SchemaClass/Result/LastAction.pm blib/lib/WorldOfAnime/SchemaClass/Result/LastAction.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UserFriends.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserFriends.pm \
	  lib/WorldOfAnime/Model/Galleries/Gallery.pm blib/lib/WorldOfAnime/Model/Galleries/Gallery.pm \
	  lib/WorldOfAnime/SchemaClass/Result/QAAnswers.pm blib/lib/WorldOfAnime/SchemaClass/Result/QAAnswers.pm \
	  lib/WorldOfAnime/SchemaClass/Result/AdAffiliates.pm blib/lib/WorldOfAnime/SchemaClass/Result/AdAffiliates.pm \
	  lib/WorldOfAnime/Model/Reviews/AnimeReview.pm blib/lib/WorldOfAnime/Model/Reviews/AnimeReview.pm \
	  lib/WorldOfAnime/Controller/Forums.pm blib/lib/WorldOfAnime/Controller/Forums.pm \
	  lib/WorldOfAnime/Controller/Search.pm blib/lib/WorldOfAnime/Controller/Search.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Blogs.pm blib/lib/WorldOfAnime/SchemaClass/Result/Blogs.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Roles.pm blib/lib/WorldOfAnime/SchemaClass/Result/Roles.pm \
	  lib/WorldOfAnime/Model/Art/Story.pm blib/lib/WorldOfAnime/Model/Art/Story.pm \
	  lib/WorldOfAnime/Model/Messages/UserMessages.pm blib/lib/WorldOfAnime/Model/Messages/UserMessages.pm \
	  lib/WorldOfAnime/Controller/ImageGalleries.pm blib/lib/WorldOfAnime/Controller/ImageGalleries.pm \
	  lib/WorldOfAnime/Controller/Favorites.pm blib/lib/WorldOfAnime/Controller/Favorites.pm \
	  lib/WorldOfAnime/Controller/Profile.pm blib/lib/WorldOfAnime/Controller/Profile.pm \
	  lib/WorldOfAnime/SchemaClass/Result/SearchesGeneric.pm blib/lib/WorldOfAnime/SchemaClass/Result/SearchesGeneric.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Groups.pm blib/lib/WorldOfAnime/SchemaClass/Result/Groups.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Ads.pm blib/lib/WorldOfAnime/SchemaClass/Result/Ads.pm \
	  lib/WorldOfAnime/Model/S3.pm blib/lib/WorldOfAnime/Model/S3.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ArtStoryComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/ArtStoryComments.pm \
	  lib/WorldOfAnime/SchemaClass/Result/NewsArticleComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/NewsArticleComments.pm \
	  lib/WorldOfAnime/Controller/Admin.pm blib/lib/WorldOfAnime/Controller/Admin.pm \
	  lib/WorldOfAnime/Controller/DAO_ArtStory.pm blib/lib/WorldOfAnime/Controller/DAO_ArtStory.pm \
	  scratch.pm $(INST_LIB)/scratch.pm \
	  lib/WorldOfAnime/Controller/DAO_Messages.pm blib/lib/WorldOfAnime/Controller/DAO_Messages.pm \
	  lib/WorldOfAnime/View/HTML.pm blib/lib/WorldOfAnime/View/HTML.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Logins.pm blib/lib/WorldOfAnime/SchemaClass/Result/Logins.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Sessions.pm blib/lib/WorldOfAnime/SchemaClass/Result/Sessions.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/WorldOfAnime/SchemaClass/Result/DBTitleReviews.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBTitleReviews.pm \
	  lib/WorldOfAnime/Model/Polls/PollChoices.pm blib/lib/WorldOfAnime/Model/Polls/PollChoices.pm \
	  lib/WorldOfAnime/Controller/DAO_Favorites.pm blib/lib/WorldOfAnime/Controller/DAO_Favorites.pm \
	  lib/WorldOfAnime/Controller/Anime.pm blib/lib/WorldOfAnime/Controller/Anime.pm \
	  lib/WorldOfAnime/Controller/DAO_Forums.pm blib/lib/WorldOfAnime/Controller/DAO_Forums.pm \
	  lib/WorldOfAnime/Model/Formatter.pm blib/lib/WorldOfAnime/Model/Formatter.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Users.pm blib/lib/WorldOfAnime/SchemaClass/Result/Users.pm \
	  lib/WorldOfAnime/Model/Messages/PrivateMessage.pm blib/lib/WorldOfAnime/Model/Messages/PrivateMessage.pm \
	  lib/WorldOfAnime/Model/Polls/Poll.pm blib/lib/WorldOfAnime/Model/Polls/Poll.pm \
	  lib/WorldOfAnime/Controller/DAO_Games.pm blib/lib/WorldOfAnime/Controller/DAO_Games.pm \
	  lib/WorldOfAnime/Model/Users/UserProfileAppearance.pm blib/lib/WorldOfAnime/Model/Users/UserProfileAppearance.pm \
	  lib/WorldOfAnime/SchemaClass/Result/StagingNotifications.pm blib/lib/WorldOfAnime/SchemaClass/Result/StagingNotifications.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GamesInCategories.pm blib/lib/WorldOfAnime/SchemaClass/Result/GamesInCategories.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupJoinRequests.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupJoinRequests.pm \
	  lib/WorldOfAnime/SchemaClass/Result/FavoritesGalleryImages.pm blib/lib/WorldOfAnime/SchemaClass/Result/FavoritesGalleryImages.pm \
	  lib/WorldOfAnime/Controller/Notifications.pm blib/lib/WorldOfAnime/Controller/Notifications.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBTitlesToGenres.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBTitlesToGenres.pm \
	  lib/WorldOfAnime/Model/Images/Image.pm blib/lib/WorldOfAnime/Model/Images/Image.pm \
	  lib/WorldOfAnime/SchemaClass/Result/NewsArticles.pm blib/lib/WorldOfAnime/SchemaClass/Result/NewsArticles.pm \
	  lib/WorldOfAnime/Model/Galleries/UserGalleries.pm blib/lib/WorldOfAnime/Model/Galleries/UserGalleries.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBChanges.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBChanges.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Galleries.pm blib/lib/WorldOfAnime/SchemaClass/Result/Galleries.pm \
	  lib/WorldOfAnime/Controller/Root.pm blib/lib/WorldOfAnime/Controller/Root.pm \
	  lib/WorldOfAnime/SchemaClass/Result/BlogSubscriptions.pm blib/lib/WorldOfAnime/SchemaClass/Result/BlogSubscriptions.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ForumCategories.pm blib/lib/WorldOfAnime/SchemaClass/Result/ForumCategories.pm \
	  lib/WorldOfAnime/Controller/Tags.pm blib/lib/WorldOfAnime/Controller/Tags.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/WorldOfAnime/SchemaClass/Result/UserComments.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserComments.pm \
	  lib/WorldOfAnime/Controller/QA.pm blib/lib/WorldOfAnime/Controller/QA.pm \
	  lib/WorldOfAnime/Model/Images/GalleryImage.pm blib/lib/WorldOfAnime/Model/Images/GalleryImage.pm \
	  SendWaitingEmailsHTML.pl $(INST_LIB)/SendWaitingEmailsHTML.pl \
	  lib/WorldOfAnime/SchemaClass/Result/PollQuestions.pm blib/lib/WorldOfAnime/SchemaClass/Result/PollQuestions.pm \
	  lib/WorldOfAnime/SchemaClass/Result/PrivateMessages.pm blib/lib/WorldOfAnime/SchemaClass/Result/PrivateMessages.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GalleryImagesToTags.pm blib/lib/WorldOfAnime/SchemaClass/Result/GalleryImagesToTags.pm \
	  lib/WorldOfAnime/SchemaClass/Result/DBCategories.pm blib/lib/WorldOfAnime/SchemaClass/Result/DBCategories.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Searches.pm blib/lib/WorldOfAnime/SchemaClass/Result/Searches.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Games.pm blib/lib/WorldOfAnime/SchemaClass/Result/Games.pm \
	  lib/WorldOfAnime/Model/DB.pm blib/lib/WorldOfAnime/Model/DB.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ForumThreadSubscriptions.pm blib/lib/WorldOfAnime/SchemaClass/Result/ForumThreadSubscriptions.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ForumForums.pm blib/lib/WorldOfAnime/SchemaClass/Result/ForumForums.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UsersToRoles.pm blib/lib/WorldOfAnime/SchemaClass/Result/UsersToRoles.pm \
	  lib/WorldOfAnime/SchemaClass/Result/QAQuestions.pm blib/lib/WorldOfAnime/SchemaClass/Result/QAQuestions.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Notifications.pm blib/lib/WorldOfAnime/SchemaClass/Result/Notifications.pm \
	  lib/WorldOfAnime/Model/Users/UserProfile.pm blib/lib/WorldOfAnime/Model/Users/UserProfile.pm \
	  lib/WorldOfAnime/SchemaClass/Result/EmailTemplates.pm blib/lib/WorldOfAnime/SchemaClass/Result/EmailTemplates.pm \
	  lib/WorldOfAnime/Controller/Email.pm blib/lib/WorldOfAnime/Controller/Email.pm \
	  lib/WorldOfAnime/SchemaClass/Result/LinksCategories.pm blib/lib/WorldOfAnime/SchemaClass/Result/LinksCategories.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Referrals.pm blib/lib/WorldOfAnime/SchemaClass/Result/Referrals.pm \
	  lib/WorldOfAnime/SchemaClass/Result/QASubscriptions.pm blib/lib/WorldOfAnime/SchemaClass/Result/QASubscriptions.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UserActions.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserActions.pm \
	  lib/WorldOfAnime/SchemaClass/Result/GroupLogs.pm blib/lib/WorldOfAnime/SchemaClass/Result/GroupLogs.pm \
	  lib/WorldOfAnime/Controller/DAO_Comments.pm blib/lib/WorldOfAnime/Controller/DAO_Comments.pm \
	  lib/WorldOfAnime/Controller/Messages.pm blib/lib/WorldOfAnime/Controller/Messages.pm 
	$(NOECHO) $(ABSPERLRUN) -MExtUtils::Install -e 'pm_to_blib({@ARGV}, '\''$(INST_LIB)/auto'\'', q[$(PM_FILTER)], '\''$(PERM_DIR)'\'')' -- \
	  lib/WorldOfAnime/Controller/DAO_ImageTags.pm blib/lib/WorldOfAnime/Controller/DAO_ImageTags.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Actions.pm blib/lib/WorldOfAnime/SchemaClass/Result/Actions.pm \
	  lib/WorldOfAnime/Model/Users/User.pm blib/lib/WorldOfAnime/Model/Users/User.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Tags.pm blib/lib/WorldOfAnime/SchemaClass/Result/Tags.pm \
	  lib/WorldOfAnime/Controller/Polls.pm blib/lib/WorldOfAnime/Controller/Polls.pm \
	  lib/WorldOfAnime/Model/Art/StoryChapter.pm blib/lib/WorldOfAnime/Model/Art/StoryChapter.pm \
	  lib/WorldOfAnime/Controller/Users.pm blib/lib/WorldOfAnime/Controller/Users.pm \
	  lib/WorldOfAnime/Model/Reviews/Review.pm blib/lib/WorldOfAnime/Model/Reviews/Review.pm \
	  lib/WorldOfAnime/SchemaClass/Result/UserProfileSiteNotifications.pm blib/lib/WorldOfAnime/SchemaClass/Result/UserProfileSiteNotifications.pm \
	  lib/WorldOfAnime/SchemaClass/Result/ChatUsers.pm blib/lib/WorldOfAnime/SchemaClass/Result/ChatUsers.pm \
	  lib/WorldOfAnime/Controller/DAO_Images.pm blib/lib/WorldOfAnime/Controller/DAO_Images.pm \
	  lib/WorldOfAnime/SchemaClass/Result/Timezones.pm blib/lib/WorldOfAnime/SchemaClass/Result/Timezones.pm 
	$(NOECHO) $(TOUCH) pm_to_blib


# --- MakeMaker selfdocument section:


# --- MakeMaker postamble section:


# End.
# Postamble by Module::Install 1.06
# --- Module::Install::Admin::Makefile section:

realclean purge ::
	$(RM_F) $(DISTVNAME).tar$(SUFFIX)
	$(RM_F) MANIFEST.bak _build
	$(PERL) "-Ilib" "-MModule::Install::Admin" -e "remove_meta()"
	$(RM_RF) inc

reset :: purge

upload :: test dist
	cpan-upload -verbose $(DISTVNAME).tar$(SUFFIX)

grok ::
	perldoc Module::Install

distsign ::
	cpansign -s

catalyst_par :: all
	$(NOECHO) $(PERL) -Ilib -Minc::Module::Install -MModule::Install::Catalyst -e"Catalyst::Module::Install::_catalyst_par( '', 'WorldOfAnime', { CLASSES => [], PAROPTS =>  {}, ENGINE => 'CGI', SCRIPT => '', USAGE => q## } )"
# --- Module::Install::AutoInstall section:

config :: installdeps
	$(NOECHO) $(NOOP)

checkdeps ::
	$(PERL) Makefile.PL --checkdeps

installdeps ::
	$(NOECHO) $(NOOP)

installdeps_notest ::
	$(NOECHO) $(NOOP)

upgradedeps ::
	$(PERL) Makefile.PL --config= --upgradedeps=Catalyst::Runtime,5.80007,Catalyst::Plugin::ConfigLoader,0,Catalyst::Plugin::Static::Simple,0,Catalyst::Action::RenderView,0,parent,0,Config::General,0

upgradedeps_notest ::
	$(PERL) Makefile.PL --config=notest,1 --upgradedeps=Catalyst::Runtime,5.80007,Catalyst::Plugin::ConfigLoader,0,Catalyst::Plugin::Static::Simple,0,Catalyst::Action::RenderView,0,parent,0,Config::General,0

listdeps ::
	@$(PERL) -le "print for @ARGV" 

listalldeps ::
	@$(PERL) -le "print for @ARGV" Catalyst::Runtime Catalyst::Plugin::ConfigLoader Catalyst::Plugin::Static::Simple Catalyst::Action::RenderView parent Config::General

