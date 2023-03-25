package GraphQL::Tiny::Type::Schema;
use strict;
use warnings;

use Type::Library
    -base,
    -declare => qw( GraphQLSchemaExtensions );

use Type::Utils;
use Types::Standard -types;

# Custom extensions
#
# remarks:
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
declare 'GraphQLSchemaExtensions',
  Dict[attributeName => Any];

1;
