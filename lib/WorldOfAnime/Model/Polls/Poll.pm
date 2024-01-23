package WorldOfAnime::Model::Polls::Poll;
use Moose;
use JSON;

BEGIN { extends 'Catalyst::Model' }

has 'id' => (
    is => 'rw',
    isa => 'Int',
);

has 'group_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'created_by' => (
    is => 'rw',
    isa => 'Str',
);

has 'created_by_user_id' => (
    is => 'rw',
    isa => 'Int',
);

has 'poll' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'total_votes' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'status' => (
    is => 'rw',
    isa => 'Int',
);

has 'choices' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'createdate' => (
  is => 'rw',
  isa => 'DateTime',
);



sub build {
    my $self = shift;
    my ( $c, $id ) = @_;
    
    $self->empty();

    my $cid = "woa:poll:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->id( $cached->id );
        $self->group_id( $cached->group_id );
        $self->created_by( $cached->created_by );
        $self->created_by_user_id( $cached->created_by_user_id );
        $self->poll( $cached->poll );
        $self->status( $cached->status );
	$self->createdate( $cached->createdate );

    } else {

        my $Poll = $c->model('DB::PollQuestions')->find($id);

	if (defined($Poll)) {
            
	    $self->id( $Poll->id );
            $self->group_id( $Poll->group_id );
            $self->created_by( $Poll->created_by_user->username );
            $self->created_by_user_id( $Poll->created_by );
            $self->poll( $Poll->poll );
            $self->status( $Poll->status );
	    $self->createdate( $Poll->createdate );

            $c->cache->set($cid, $self, 2592000);
        }
    }
}


sub build_choices {
    my $self = shift;
    my ( $c ) = @_;

    my $id = $self->id;

    $self->choices("");

    my $cid = "woa:poll_choices:$id";
    my $cached = $c->cache->get($cid);
    
    if (defined($cached)) {

        $self->choices( $cached->choices );

    } else {

        my $choices; # json
        my $total_votes = 0;
        my $Choices = $c->model('DB::PollChoices')->search({
            -and => [
                poll_id => $id,
                status  => 1,
            ],
            });

	if (defined($Choices)) {

            while (my $choice = $Choices->next) {
                my $choice_id      = $choice->id;
                my $text           = $choice->choice;
                my $votes          = $choice->votes;
                $total_votes      += $votes;

                push (@{ $choices} , { 'choice_id' => "$choice_id", 'choice' => "$text", 'votes' => "$votes" });
            }
        }        

        if ($choices) { $self->choices( to_json($choices)); $self->total_votes( $total_votes ); }

        $c->cache->set($cid, $self, 2592000);

    }
}


sub empty {
    my $self = shift;

    $self->id(0);    
    $self->poll("");
}


sub clear {
    my $self = shift;
    my ( $c ) = @_;

    my $id = $self->id;
    my $cid = "woa:poll:$id";
    $c->cache->remove($cid);
}

__PACKAGE__->meta->make_immutable;

1;
