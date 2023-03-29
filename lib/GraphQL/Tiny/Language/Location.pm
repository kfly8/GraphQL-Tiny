package GraphQL::Tiny::Language::Location;
use strict;
use warnings;
use utf8;

use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type -all;
use GraphQL::Tiny::Utils::Invariant qw(invariant);

our @EXPORT_OK = qw(get_location);

use Type::Library -base, -declare => qw(SourceLocation);

use GraphQL::Tiny::Language::Source qw(Source);

#
# Represents a location in a Source.
#
type 'SourceLocation',
    as Dict[
        line => Int,
        column => Int,
    ];

my $LINE_REG_EXP = qr/\r\n|[\n\r]/;

#
# Takes a Source and a UTF-8 character offset, and returns the corresponding
# line and column as a SourceLocation.
#
sub get_location {
    my ($source, $position) = @_;

    if (ASSERT) {
        Source->assert_valid($source);
        Int->assert_valid($position);
    }

    my $last_line_start = 0;
    my $line = 1;

    pos($source->{body}) = 1; # reset position
    while ($source->{body} =~ m!($LINE_REG_EXP)!g) {
        my $pos = pos($source->{body});
        my $index = $pos - length($1);
        invariant(Int->check($index));
        if ($index >= $position) {
            last;
        }
        $last_line_start = $pos;
        $line += 1;
    }
    return { line => $line, column => $position + 1 - $last_line_start };
}

1;
