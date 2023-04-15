package GraphQL::Tiny::Error::SyntaxError;
use strict;
use warnings;
use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);
use GraphQL::Tiny::Inner::TypeLibrary qw(Int Str);

use GraphQL::Tiny::Language::Source qw(Source);

use GraphQL::Tiny::Error::GraphQLError qw(build_graphql_error);

use Exporter 'import';

our @EXPORT_OK = qw(syntax_error);

# Produces a GraphQLError representing a syntax error, containing useful
# descriptive information about the syntax error's position in the source.
sub syntax_error {
    my ($source, $position, $description) = @_;

    if (ASSERT) {
        Source->assert_valid($source);
        Int->assert_valid($position);
        Str->assert_valid($description);
    }

    return build_graphql_error("Syntax Error: $description", {
        source => $source,
        positions => [$position],
    });
}

1;
