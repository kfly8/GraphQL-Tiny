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
__END__

=encoding utf-8

=head1 NAME

GraphQL::Tiny::Error - GraphQL error utilities

=head1 SYNOPSIS

    use GraphQL::Tiny::Error qw(
        build_graphql_error
        GraphQLError
        GraphQLErrorOptions
        GraphQLFormattedError
        GraphQLErrorExtensions
        syntax_error
        located_error
    );

=head1 DESCRIPTION

The `graphql/error` module is responsible for creating and formatting
GraphQL errors.

