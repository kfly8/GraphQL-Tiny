package GraphQL::Tiny::Utils::DevAssert;
use strict;
use warnings;

use Carp qw(croak);
use GraphQL::Tiny::Utils::Error qw(build_error);

use Exporter 'import';

our @EXPORT_OK = qw(ASSERT dev_assert);

use constant ASSERT => !!$ENV{GRAPHQL_TINY_ASSERT};

sub dev_assert {
    my ($condition, $message) = @_;
    if (!$condition) {
        croak build_error($message);
    }
}

1
