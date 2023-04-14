use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Printer qw(ast_print);

use GraphQL::Tiny::Language::Kinds qw(Kind);

TODO: {
    local $TODO = 'test not implemented';

    subtest 'Printer: Query document' => sub {
        subtest 'it prints minimal ast' => sub {
            my $ast = {
                kind => Kind['FIELD'],
                name => { kind => Kind['NAME'], value => 'foo' },
            };
            is ast_print($ast), 'foo';
        };
    };
};

done_testing;
