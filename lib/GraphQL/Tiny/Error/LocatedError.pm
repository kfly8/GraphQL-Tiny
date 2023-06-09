package GraphQL::Tiny::Error::LocatedError;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeUtils qw(type as);
use GraphQL::Tiny::Inner::TypeLibrary qw(
    Int
    Maybe
    Null
    ReadonlyArray
    Str
    Undef
    Unknown
);

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);
use GraphQL::Tiny::Utils::Error qw(to_error);

use GraphQL::Tiny::Language::Ast qw(ASTNode);
use GraphQL::Tiny::Error::GraphQLError qw(build_graphql_error GraphQLError);

use Exporter 'import';

our @EXPORT_OK = qw(located_error);

use Type::Library -base, -declare => qw(LocatedErrorArgsNodes);

type 'LocatedErrorArgsNodes',
    as Maybe[ReadonlyArray[ASTNode] | ASTNode | Null | Undef];

# Given an arbitrary value, presumably thrown while attempting to execute a
# GraphQL operation, produce a new GraphQLError aware of the location in the
# document responsible for the original Error.
sub located_error {
    my ($raw_original_error, $nodes, $path) = @_;

    if (ASSERT) {
        Unknown->assert_valid($raw_original_error);

        LocatedErrorArgsNodes->assert_valid($nodes);

        my $Path = ReadonlyArray[Str|Int];
        $Path->assert_valid($path) if $path;
    }

    my $original_error = to_error($raw_original_error);

    # Note: this uses a brand-check to support GraphQL errors originating from other contexts.
    if (is_located_graphql_error($original_error)) {
        return $original_error;
    }

    return build_graphql_error($original_error->{message}, {
        nodes => ($original_error->{nodes} // $nodes),
        source => $original_error->{source},
        positions => $original_error->{positions},
        path => $path,
        originalError => $original_error,
    });
}

# @return error is GraphQLError
sub is_located_graphql_error {
    my ($error) = @_;

    # (graphql-js) Array.isArray(error.path);
    return ref $error && ref $error eq 'HASH' && ref $error->{path} && ref $error->{path} eq 'ARRAY';
}

1;
