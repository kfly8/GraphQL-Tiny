use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::IdentityFunc qw(identity_func);

subtest 'it returns the first argument it receives' => sub {
    is identity_func(), undef;
    is identity_func(undef), undef;

    my $obj = {};
    is identity_func($obj), $obj;

    is identity_func('foo', 'bar'), 'foo';
};

done_testing;
