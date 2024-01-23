package WorldOfAnime::Model::DB;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'WorldOfAnime::SchemaClass',
    connect_info => [
        'dbi:mysql:worldofanime',
    ],
);

=head1 NAME

WorldOfAnime::Model::DB - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

meeko,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
