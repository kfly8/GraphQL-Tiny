use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{GRAPHQL_TINY_ASSERT} = 1;
}

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT dev_assert);

subtest 'ASSERT' => sub {
    ok ASSERT;
};

subtest 'dev_assert' => sub {
    eval { dev_assert(0, 'foo') };
    my $error = $@;
    is $error->{message}, 'foo';
};

done_testing;
