use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Type::Definition qw(
    build_graphql_scalar_type
);

use GraphQL::Tiny::Type::Definition qw(
    GraphQLScalarType
);

use GraphQL::Tiny::Utils::IdentityFunc qw(identity_func);

my $scalar_type = build_graphql_scalar_type({ name => 'Scalar' });
ok GraphQLScalarType->check($scalar_type), 'build GraphQLScalarType';

subtest 'Type System: Scalar' => sub {
    subtest 'it accepts a Scalar type defining serialize' => sub {
        eval { build_graphql_scalar_type({ name => 'SomeScalar' }) };
        ok !$@;
    };

    subtest 'it accepts a Scalar type defining specifiedByURL' => sub {
        eval {
            build_graphql_scalar_type({
                name => 'SomeScalar',
                specifiedByURL => 'https://example.com/foo_spec',
            });
        };
        ok !$@;
    };

    subtest 'it accepts a Scalar type defining parseValue and parseLiteral' => sub {
        eval {
            build_graphql_scalar_type({
                name => 'SomeScalar',
                parseValue => sub { ... },
                parseLiteral => sub { ... },
            });
        };
        ok !$@;
    };

    subtest 'it provides default methods if omitted' => sub {
        my $scalar = build_graphql_scalar_type({ name => 'Foo' });

        is $scalar->{serialize}, \&identity_func;
        is $scalar->{parseValue}, \&identity_func;
        is ref $scalar->{parseLiteral}, 'CODE';
    };

    subtest 'it use parseValue for parsing literals if parseLiteral omitted' => sub {
        my $scalar = build_graphql_scalar_type({
            name => 'Foo',
            parseValue => sub { 'parseValue: ' . $_[0] },
        });

        pass;

        TODO: {
            todo_skip 'not implemented: parse_value, value_from_ast_untyped', 3;

            is $scalar->{parseLiteral}->('null'), 'parseValue: null';
            is $scalar->{parseLiteral}->('{ foo: "bar" }'), 'parseValue: { foo: "bar" }';
            is $scalar->{parseLiteral}->(parse_value('{ foo: { bar: $var } }', { var => 'baz' })), 'parseValue: { foo: { bar: "baz" } }';
        };
    };

    subtest 'it rejects a Scalar type defining serialize but not parseValue' => sub {
        eval {
            build_graphql_scalar_type({
                name => 'SomeScalar',
                parseLiteral => sub { ... },
            });
        };

        my $err = $@;
        is $err->{message}, 'SomeScalar must provide both "parseValue" and "parseLiteral" functions.';
    };
};

done_testing;
