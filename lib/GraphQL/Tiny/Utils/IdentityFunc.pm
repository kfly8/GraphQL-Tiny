package GraphQL::Tiny::Utils::IdentityFunc;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(identity_func);

# Returns the first argument it receives.
sub identity_func {
    return $_[0];
}

1;
