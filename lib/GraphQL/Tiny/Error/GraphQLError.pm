package GraphQL::Tiny::Error::GraphQLError;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Type -all;

use Type::Library -base, -declare => qw(
    GraphQLErrorExtensions
);

#
# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
#
type 'GraphQLErrorExtensions',
    as Dict[
        attributeName => Unknown,
    ];

1;

