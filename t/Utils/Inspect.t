use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Inspect qw(inspect);

subtest 'inspect' => sub {
    subtest 'undefined' => sub {
        is inspect(undef), 'undef';
    };

    subtest 'boolean' => sub {
        # NOTE: Not a faithful port.
        # There is no built-in boolean in perl;
        # Sclar reference \1, \0 are sometimes used as a substitute for true/false,
        # e.g. in JSON encoding, so test with that.
        is inspect(\1), '\1';
        is inspect(\0), '\0';
    };

    subtest 'string' => sub {
        is inspect(''), '""';
        is inspect('abc'), '"abc"';
        is inspect('"'), '"\\""';
    };

    subtest 'number' => sub {
        is inspect(0.0), '0';
        is inspect(123), '123';
        is inspect(3.14), '"3.14"', 'NOTE: Not a faithful port. float number treated as string.';
        is inspect('NaN'), '"NaN"';
        is inspect('Infinity'), '"Infinity"';
        is inspect('-Infinity'), '"-Infinity"';
    };

    subtest 'function' => sub {
        is inspect(sub {}), 'sub { "DUMMY" }', 'unname function';

        sub named_func { }
        is inspect(\&named_func), 'sub { "DUMMY" }', 'NOTE: Named function names are not displayed.';
    };

    subtest 'arrayref' => sub {
        is inspect([]), '[]';
        is inspect([undef]), '[undef]';
        is inspect([1,'NaN']), '[1,"NaN"]';
        is inspect([['a','b'], 'c']), '[["a","b"],"c"]';

        is inspect([[[]]]), '[[[]]]';
        is inspect([[['a']]]), '[[["a"]]]', 'NOTE: Not a faithful port. Even if the depth of recursion is more than 3, it will still be displayed.';

        is inspect([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), '[0,1,2,3,4,5,6,7,8,9]';

        is inspect([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]), '[0,1,2,3,4,5,6,7,8,9,10]', 'NOTE: Not a faithful port. 10 items are displayed.';
        is inspect([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]), '[0,1,2,3,4,5,6,7,8,9,10,11]', 'NOTE: Not a faithful port. 11 items are displayed.';
    };

    subtest 'hashref' => sub {
        is inspect({}), '{}';
        is inspect({ a => 1 }), '{"a" => 1}';
        is inspect({ a => 1, b => 2 }), '{"a" => 1,"b" => 2}';
        is inspect({ array => [undef, 0] }), '{"array" => [undef,0]}';

        is inspect({ a => { b => {} } }), '{"a" => {"b" => {}}}';
        is inspect({ a => { b => { c => 1 } } }), '{"a" => {"b" => {"c" => 1}}}';

        my $map = {};
        $map->{a} = 1;
        $map->{b} = 2;
        is inspect($map), '{"a" => 1,"b" => 2}';
    };

    TODO: {
        local $TODO = 'toJSON is not supported yet';
        subtest 'use toJSON if provided' => sub { };

        subtest 'it handles toJSON that return `this` should work' => sub { };

        subtest 'it handles toJSON returning object values' => sub { };

        subtest 'it handles toJSON function that uses this' => sub { };
    };

    subtest 'it detect circular objects' => sub {
        my $obj = {};
        $obj->{self} = $obj;
        $obj->{deepSelf} = { self => $obj };

        is inspect($obj), '{"deepSelf" => {"self" => $VAR1},"self" => $VAR1}';

        my $array = [];
        $array->[0] = $array;
        $array->[1] = [$array];
        is inspect($array), '[$VAR1,[$VAR1]]';

        my $mixed = { array => [] };
        $mixed->{array}[0] = $mixed;
        is inspect($mixed), '{"array" => [$VAR1]}';

        TODO: {
            local $TODO = 'toJSON is not supported yet';
            #
            #        my $customA = {
            #            toJSON => sub { $customB },
            #        };
            #
            #        my $customB = {
            #            toJSON => sub { $customA },
            #        };
            #
            #        is inspect($customA), '[Circular]';
        };
    };

    subtest 'it use class names for the short form of an object' => sub {
        my $obj = bless {foo => 'bar'}, 'Foo';
        is inspect($obj), 'bless( {"foo" => "bar"}, \'Foo\' )';

        TODO: {
            local $TODO = 'Symbol.toStringTag is not supported yet';
            my $obj2 = bless {}, 'Foo2';
            $obj2->{Symbol_toStringTag} = 'Bar';
            is inspect($obj2), '[Bar]';
        };

        my $obj3 = bless {};
        is inspect($obj3), 'bless( {}, \'main\' )', 'If package is not specified in bless, "main" is used.';
    };
};

done_testing;
