package GraphQL::Tiny::Language::PrintString;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(print_string);

my $ESCAPED_REG_EXP = qr/[\x00-\x1f\x22\x5c\x7f-\x9f]/;

my $ESCAPE_SEQUENCES = [
    '\\u0000', '\\u0001', '\\u0002', '\\u0003', '\\u0004', '\\u0005', '\\u0006', '\\u0007',
    '\\b',     '\\t',     '\\n',     '\\u000B', '\\f',     '\\r',     '\\u000E', '\\u000F',
    '\\u0010', '\\u0011', '\\u0012', '\\u0013', '\\u0014', '\\u0015', '\\u0016', '\\u0017',
    '\\u0018', '\\u0019', '\\u001A', '\\u001B', '\\u001C', '\\u001D', '\\u001E', '\\u001F',
    '',        '',        '\\"',     '',        '',        '',        '',        '',
    '',        '',        '',        '',        '',        '',        '',        '', # 2F
    '',        '',        '',        '',        '',        '',        '',        '',
    '',        '',        '',        '',        '',        '',        '',        '', # 3F
    '',        '',        '',        '',        '',        '',        '',        '',
    '',        '',        '',        '',        '',        '',        '',        '', # 4F
    '',        '',        '',        '',        '',        '',        '',        '',
    '',        '',        '',        '',        '\\\\',    '',        '',        '', # 5F
    '',        '',        '',        '',        '',        '',        '',        '',
    '',        '',        '',        '',        '',        '',        '',        '', # 6F
    '',        '',        '',        '',        '',        '',        '',        '',
    '',        '',        '',        '',        '',        '',        '',        '\\u007F',
    '\\u0080', '\\u0081', '\\u0082', '\\u0083', '\\u0084', '\\u0085', '\\u0086', '\\u0087',
    '\\u0088', '\\u0089', '\\u008A', '\\u008B', '\\u008C', '\\u008D', '\\u008E', '\\u008F',
    '\\u0090', '\\u0091', '\\u0092', '\\u0093', '\\u0094', '\\u0095', '\\u0096', '\\u0097',
    '\\u0098', '\\u0099', '\\u009A', '\\u009B', '\\u009C', '\\u009D', '\\u009E', '\\u009F',
];

# Prints a string as a GraphQL StringValue literal. Replaces control characters
# and excluded characters (" U+0022 and \\ U+005C) with escape sequences.
sub print_string {
    my ($str) = @_;
    my $escaped = $str =~ s/($ESCAPED_REG_EXP)/escaped_replacer($1)/ger;
    return qq{"$escaped"};
}

sub escaped_replacer {
    my ($char) = @_;
    return $ESCAPE_SEQUENCES->[ord $char];
}

1;
