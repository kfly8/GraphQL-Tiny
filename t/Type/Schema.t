use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Type::Schema qw(GraphQLSchemaExtensions);

subtest 'GraphQLSchemaExtensions' => sub {
    isa_ok GraphQL::Tiny::Type::Schema::GraphQLSchemaExtensions, 'Type::Tiny';
};

done_testing;
