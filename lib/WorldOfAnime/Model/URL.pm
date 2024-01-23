package WorldOfAnime::Model::URL;
use Moose;
use WWW::Shorten::Bitly;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Model' }

has 'url' => (
  is => 'rw',
  isa => 'Str',
);

has 'shortener' => (
    is => 'rw',
    isa => 'Str',
    default => 'bitly',
);

sub shorten {
    my ($self) = shift;
    my $short_url = "foo";
    
    if ($self->shortener eq "bitly") {
        # I know its bad to have these here.  Move them sometime
        
        my $user = 'worldofanime';
        my $key      = 'R_e7d03eaf76df3ba844818da2c839a367';
        
        my $bitly = WWW::Shorten::Bitly->new(URL => $self->url, USER => $user, APIKEY => $key);
        
        $short_url = $bitly->shorten(URL => $self->url);
    }

    return $short_url;
}

1;