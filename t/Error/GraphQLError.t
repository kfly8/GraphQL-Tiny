use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Error::GraphQLError qw(GraphQLErrorExtensions);

subtest 'GraphQLErrorExtensions' => sub {
    isa_ok GraphQLErrorExtensions, 'Type::Tiny';
};

done_testing;
