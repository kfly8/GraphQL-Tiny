use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Error::GraphQLError qw(GraphQLError);
use GraphQL::Tiny::Type::AssertName qw(assert_name assert_enum_value_name);

subtest 'assert_name' => sub {
    local $@;

    eval { assert_name('foo') };
    ok !$@;

    eval { assert_name('') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Expected name to be a non-empty string.';

    eval { assert_name('aå') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Names must start with [_a-zA-Z] and only contain [_a-zA-Z0-9] but "aå" does not.';

    eval { assert_name('1foo') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Names must start with [_a-zA-Z] and only contain [_a-zA-Z0-9] but "1foo" does not.';
};

subtest 'assert_enum_value_name' => sub {
    local $@;

    eval { assert_enum_value_name('foo') };
    ok !$@;

    eval { assert_enum_value_name('true') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Enum values cannot be named: true';

    eval { assert_enum_value_name('false') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Enum values cannot be named: false';

    eval { assert_enum_value_name('null') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Enum values cannot be named: null';

    eval { assert_enum_value_name('') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Expected name to be a non-empty string.';

    eval { assert_enum_value_name('aå') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Names must start with [_a-zA-Z] and only contain [_a-zA-Z0-9] but "aå" does not.';

    eval { assert_enum_value_name('1foo') };
    ok GraphQLError->check($@);
    is $@->{message}, 'Names must start with [_a-zA-Z] and only contain [_a-zA-Z0-9] but "1foo" does not.';
};

done_testing;
