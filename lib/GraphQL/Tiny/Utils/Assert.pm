package GraphQL::Tiny::Utils::Assert;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(ASSERT);

use constant ASSERT => !!$ENV{GRAPHQL_TINY_ASSERT};

1;
