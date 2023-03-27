use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Error::GraphQLError qw(GraphQLErrorExtensions);

subtest 'GraphQLErrorExtensions' => sub {
    isa_ok GraphQLErrorExtensions, 'Type::Tiny';
    ok GraphQLErrorExtensions->is_strictly_subtype_of('Dict');
    is GraphQLErrorExtensions, 'GraphQLErrorExtensions';
};

done_testing;
