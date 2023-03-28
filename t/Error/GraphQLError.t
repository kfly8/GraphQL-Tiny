use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Type -types;
use GraphQL::Tiny::Error::GraphQLError qw(GraphQLErrorExtensions GraphQLErrorOptions);

subtest 'GraphQLErrorExtensions' => sub {
    isa_ok GraphQLErrorExtensions, 'Type::Tiny';
    is GraphQLErrorExtensions, 'GraphQLErrorExtensions';

    my $Dict = GraphQLErrorExtensions->parent;
    my %params = @{$Dict->parameters};

    ok $params{attributeName};
};

subtest 'GraphQLErrorOptions' => sub {
    isa_ok GraphQLErrorOptions, 'Type::Tiny';
    is GraphQLErrorOptions, 'GraphQLErrorOptions';

    my $Dict = GraphQLErrorOptions->parent;
    my %params = @{$Dict->parameters};

    ok $params{nodes};
    ok $params{source};
    ok $params{positions};
    ok $params{originalError};
    ok $params{extensions};
};

done_testing;
