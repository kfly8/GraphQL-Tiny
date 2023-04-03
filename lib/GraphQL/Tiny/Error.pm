package GraphQL::Tiny::Error;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    build_graphql_error

    GraphQLError
    GraphQLErrorOptions
    GraphQLFormattedError

    syntax_error
    located_error
);

use GraphQL::Tiny::Error::GraphQLError qw(build_graphql_error);

use GraphQL::Tiny::Error::GraphQLError qw(
    GraphQLError
    GraphQLErrorOptions
    GraphQLFormattedError
    GraphQLErrorExtensions
);

use GraphQL::Tiny::Error::SyntaxError qw(syntax_error);

use GraphQL::Tiny::Error::LocatedError qw(located_error);

1;
