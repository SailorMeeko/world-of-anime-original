package WorldOfAnime::Model::Amazon::Associates;
use Moose;
use JSON;


has 'tracking_id' => (
  is => 'rw',
  isa => 'Str',
  default => 'worldofanime09-20',
);


sub BUILD {
    my $self = shift;
    my ( $c ) = @_;
    
}



1;