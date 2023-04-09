package GraphQL::Tiny::Utils::Inspect;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(inspect);

use Data::Dumper ();

# Used to print values in error messages.
sub inspect {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Sortkeys = 1;

    return Data::Dumper::Dumper($_[0]);
}

1;
