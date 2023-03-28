package GraphQL::Tiny::Utils::Invariant;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type qw(Error);

use Carp qw(croak longmess);

use Exporter 'import';

our @EXPORT = qw(invariant);

sub invariant {
    my ($condition, $message) = @_;

    if (!$condition) {
        my $error = {
            name => 'Error',
            message => $message // 'Unexpected invariant triggered.',
            stack => longmess(),
        };
        if (ASSERT) {
            Error->assert_valid($error);
        }
        croak $error;
    }
}

1;
