use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{GRAPHQL_TINY_ASSERT} = 1;
}

use GraphQL::Tiny::Utils::Assert qw(ASSERT);

ok ASSERT;

done_testing;
