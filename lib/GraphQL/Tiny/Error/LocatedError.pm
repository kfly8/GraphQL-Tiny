package GraphQL::Tiny::Error::LocatedError;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type -all;
use GraphQL::Tiny::Utils::Error qw(to_error);

use GraphQL::Tiny::Language::AST qw(ASTNode);
use GraphQL::Tiny::Error::GraphQLError qw(build_graphql_error GraphQLError);

use Exporter 'import';

our @EXPORT_OK = qw(located_error);

# Given an arbitrary value, presumably thrown while attempting to execute a
# GraphQL operation, produce a new GraphQLError aware of the location in the
# document responsible for the original Error.
sub located_error {
    my ($raw_original_error, $nodes, $path) = @_;

    if (ASSERT) {
        Unkown->assert_valid($raw_original_error);

        my $NodesType = ASTNode() | ReadonlyArray[ASTNode] | Undef | Null;
        $NodesType->assert_valid($nodes);

        if (defined $path) {
            ReadonlyArray[Str|Int]->assert_valid($path);
        }
    }

    my $original_error = to_error($raw_original_error);

    # Note: this uses a brand-check to support GraphQL errors originating from other contexts.
    if (is_located_graphql_error($original_error)) {
        return $original_error;
    }

    return build_graphql_error(
        nodes => ($original_error->{nodes} // $nodes),
        source => $original_error->{source},
        positions => $original_error->{positions},
        path => $path,
        original_error => $original_error,
    );
}

# @return error is GraphQLError
sub is_located_graphql_error {
    my ($error) = @_;

    # (original) Array.isArray(error.path);
    return ref $error && ref $error eq 'HASH' && ref $error->{path} && ref $error->{path} eq 'ARRAY';
}

1;
