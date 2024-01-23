package WorldOfAnime;

use strict;
no warnings;

use Catalyst::Runtime 5.80;
use Cache::Memcached::GetParserXS;
use Cache::Memcached;

use parent qw/Catalyst/;
use Catalyst qw/-Debug
                ConfigLoader
                Static::Simple
                Cache
                Authentication
                Authorization::Roles
                Session
                Session::State::Cookie
                Session::Store::FastMmap/;
our $VERSION = '1.0';

__PACKAGE__->config( name => 'WorldOfAnime',
                    session => {flash_to_stash => 1});
__PACKAGE__->config( uploadtmp => '/tmp' );
__PACKAGE__->config( default_view => 'HTML' );

__PACKAGE__->config(
		'Plugin::Session' => {
            	expires => 43200,
            	storage => '/tmp/session'
	        },
  	  );


__PACKAGE__->config->{'Plugin::Cache'}{backend} = {
    class   => "Cache::Memcached",
    servers => ['127.0.0.1:11211'],
};






# location of images on fileserver


# For web site - sasami
#__PACKAGE__->config->{uploadtmpdir} = '/tmp';
#__PACKAGE__->config->{uploadfiledir} = 'root/static/images/u/';
#__PACKAGE__->config->{baseimagefiledir} = '/var/www/world-of-anime/root/static/images/';


# For local devel
__PACKAGE__->config->{uploadtmpdir} = '/tmp';
__PACKAGE__->config->{uploadfiledir} = 'root/static/images/u/';
__PACKAGE__->config->{baseimagefiledir} = '/home/meeko/projects/world-of-anime/root/static/images/';


# authentication
__PACKAGE__->config->{authentication} = 
                {  
                    default_realm => 'members',
                    realms => {
                        members => {
                            credential => {
                                class => 'Password',
                                password_field => 'password',
                                password_type => 'clear'
                            },
                            store => {
                                class => 'DBIx::Class',
                                user_model => 'Anime::Users',
                                role_relation => 'roles',
                                role_field => 'role',                   
                            }
                        }
                    }
                };
                



# Start the application
__PACKAGE__->setup();



1;
