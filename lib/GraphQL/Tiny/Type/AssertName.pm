package GraphQL::Tiny::Type::AssertName;
use strict;
use warnings;
use utf8;

use GraphQL::Tiny::Error::GraphQLError qw(build_graphql_error);
use GraphQL::Tiny::Language::CharacterClasses qw(REGEX_NAME);

use Carp qw(croak);

use Exporter 'import';

our @EXPORT_OK = qw(
  assert_name
  assert_enum_value_name
);

# Upholds the spec rules about naming.
sub assert_name {
    my ($name) = @_;

    if (length $name == 0) {
        croak build_graphql_error('Expected name to be a non-empty string.');
    }

    # XXX Use regular expressions instead of faithful porting for performance
    if ($name !~ REGEX_NAME) {
        croak build_graphql_error(
            "Names must start with [_a-zA-Z] and only contain [_a-zA-Z0-9] but \"$name\" does not."
        );
    }

    return $name;
}

# Upholds the spec rules about naming enum values.
#
# @internal
sub assert_enum_value_name {
    my ($name) = @_;

    if ($name eq 'true' || $name eq 'false' || $name eq 'null') {
        croak build_graphql_error("Enum values cannot be named: $name");
    }
    return assert_name($name);
}

1;
