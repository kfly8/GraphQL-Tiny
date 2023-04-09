package GraphQL::Tiny::Utils::Invariant;
use strict;
use warnings;
use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);
use GraphQL::Tiny::Utils::Error qw(build_error);

use Carp qw(croak);

use Exporter 'import';

our @EXPORT = qw(invariant);

sub invariant {
    my ($condition, $message) = @_;

    if (!$condition) {
        my $error = build_error($message // 'Unexpected invariant triggered.');
        croak $error;
    }
}

1;
