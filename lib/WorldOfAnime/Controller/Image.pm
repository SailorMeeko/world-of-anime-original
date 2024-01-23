package WorldOfAnime::Controller::Image;

use strict;
use warnings;
use Image::Magick;
use parent 'Catalyst::Controller';


sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    
    $c->response->body("You can't look here.");
}


sub convert_all :Path('/convert_all') {
	my ($self, $c) = @_;

	# Get all images
		
	my $Images = $c->model("DB::Images");
	
	while (my $image = $Images->next) {
		
		my $filename = $image->filename;

		    # Image Magick stuff, for figuring out width and height
        
	my $copytodir = $c->config->{baseimagefiledir};
        my $i = Image::Magick->new;
        $i->Read($copytodir . "u/{$filename}[0]");
				my $width = $i->Get('columns');
				my $height = $i->Get('rows');

				eval {
					
				### Thumbnail Image 1
				#
				my $DesiredWidth = 175;
		
				my $ThumbImage  = $i;
				my $frames = $ThumbImage->Get(text=>"%n");
				my $ThumbWidth  = $width;
				my $ThumbHeight = $height;

				if ($ThumbWidth > $DesiredWidth)
				{
					$ThumbHeight = int(($ThumbHeight / $ThumbWidth) * $DesiredWidth);
					$ThumbWidth = $DesiredWidth;
				}
			
					$ThumbImage->Thumbnail(Width => $ThumbWidth,
			                   Height => $ThumbHeight);
		
			$ThumbImage->Write($copytodir . "t175/$filename");
		};
		
	}
	

	$c->response->body("Done?");
}



1;
