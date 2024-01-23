package WorldOfAnime::Model::S3;
use Moose;
use Net::Amazon::S3;
#use Net::Amazon::S3::Client;
#use Net::Amazon::S3::Client::Bucket;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Model' }

has 'aws_access_key_id' => (
    is => 'rw',
    isa => 'Str',
    default => '0BG87FEMGFC5GG3XAMR2',
);

has 'aws_secret_access_key' => (
    is => 'rw',
    isa => 'Str',
    default => 'VqIC/x0jIg+rOJeJHtf/wklM44mFVqVqrwbUuBBP',
);

has 'client' => (
    is => 'rw',
    isa => 'Net::Amazon::S3',
);

has 'bucket' => (
    is => 'rw',
    isa => 'Str',
    default => 'images.worldofanime.com',
);



sub BUILD {
    my $self = shift;
    my ( $c ) = @_;
    
    my $s3 = Net::Amazon::S3->new(
        aws_access_key_id     => '0BG87FEMGFC5GG3XAMR2',
        aws_secret_access_key => 'VqIC/x0jIg+rOJeJHtf/wklM44mFVqVqrwbUuBBP',
        retry                 => 1,
      );

    $self->client( $s3 );
}




1;