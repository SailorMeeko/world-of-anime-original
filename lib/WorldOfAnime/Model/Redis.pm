package WorldOfAnime::Model::Redis;
use Moose;
use Redis::Client;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Model' }


has 'host' => (
    is => 'rw',
    isa => 'Str',
    default => 'localhost',
);

has 'port' => (
    is => 'rw',
    isa => 'Int',
    default => 6379,
);

has 'client' => (
    is => 'rw',
    isa => 'Redis::Client',
);


sub BUILD {
    my $self = shift;
    my ( $c ) = @_;
    
    my $redis = Redis::Client->new( host => $self->host, port => $self->port, encoding => undef );
    
    $self->client( $redis );
}


__PACKAGE__->meta->make_immutable;

1;