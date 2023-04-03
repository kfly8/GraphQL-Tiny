use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Error qw(
    build_graphql_error

    GraphQLError
    GraphQLErrorOptions
    GraphQLFormattedError

    syntax_error
    located_error
);

ok __PACKAGE__->can('build_graphql_error'), 'build_graphql_error';
ok __PACKAGE__->can('GraphQLError'), 'GraphQLError';
ok __PACKAGE__->can('GraphQLErrorOptions'), 'GraphQLErrorOptions';
ok __PACKAGE__->can('GraphQLFormattedError'), 'GraphQLFormattedError';
ok __PACKAGE__->can('syntax_error'), 'syntax_error';
ok __PACKAGE__->can('located_error'), 'located_error';

done_testing;
