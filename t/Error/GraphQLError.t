use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Error qw(Error);
use GraphQL::Tiny::Error::GraphQLError qw(
    GraphQLErrorExtensions
    GraphQLErrorOptions
    GraphQLError
    build_graphql_error
);

subtest 'GraphQLErrorExtensions' => sub {
    isa_ok GraphQLErrorExtensions, 'Type::Tiny';
    is GraphQLErrorExtensions, 'GraphQLErrorExtensions';

    ok GraphQLErrorExtensions->check({});
    ok GraphQLErrorExtensions->check({foo => 'string!'});
    ok GraphQLErrorExtensions->check({foo => 123 });
    ok GraphQLErrorExtensions->check({foo => {bar => 123}});

    # invalid cases
    ok !GraphQLErrorExtensions->check({foo => undef});
    ok !GraphQLErrorExtensions->check([]);
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

subtest 'GraphQLError' => sub {
    isa_ok GraphQLError, 'Type::Tiny';
    is GraphQLError, 'GraphQLError';

    my ($Error, $Dict) = @{GraphQLError->parent->type_constraints};
    is $Error, Error;
    ok $Dict->is_strictly_subtype_of('Dict');
};

subtest 'build_graphql_error' => sub {
    my $graphql_error = build_graphql_error('some message');
    ok GraphQLError->check($graphql_error);
};

done_testing;
