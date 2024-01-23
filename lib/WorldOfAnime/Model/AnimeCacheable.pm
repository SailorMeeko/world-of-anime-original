package WorldOfAnime::Model::AnimeCacheable;

use strict;
use base 'Catalyst::Model::DBIC::Schema';
use DBIx::Class::ResultClass::HashRefInflator;

__PACKAGE__->config(
    schema_class => 'WorldOfAnime::SchemaClass',
    connect_info => [
        'dbi:mysql:worldofanime',

    ],
);

=head1 NAME

WorldOfAnime::Model::Session - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<WorldOfAnime>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<WorldOfAnime::SchemaClass>

=head1 AUTHOR

Daniel

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
