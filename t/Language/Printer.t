use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Printer qw(ast_print);

use GraphQL::Tiny::Language::Kinds qw(KIND);

TODO: {
    local $TODO = 'test not implemented';

    subtest 'Printer: Query document' => sub {
        subtest 'it prints minimal ast' => sub {
            my $ast = {
                kind => KIND->{FIELD},
                name => { kind => KIND->{NAME}, value => 'foo' },
            };
            is ast_print($ast), 'foo';
        };
    };
};

done_testing;
