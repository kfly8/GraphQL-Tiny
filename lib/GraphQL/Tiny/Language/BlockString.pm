package GraphQL::Tiny::Language::BlockString;
use strict;
use warnings;
use utf8;

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);
use GraphQL::Tiny::Utils::Type -all;

use List::Util qw(all);

use GraphQL::Tiny::Language::CharacterClasses qw(is_white_space);

use Exporter 'import';

our @EXPORT_OK = qw(
    dedent_block_string_lines
    is_printable_as_block_string
    print_block_string
);

use constant MAX_INTEGER => 2**31 - 1;

# Produces the value of a block string from its parsed raw value, similar to
# CoffeeScript's block string, Python's docstring trim or Ruby's strip_heredoc.
#
# This implements the GraphQL spec's BlockStringValue() static algorithm.
#
# @internal
sub dedent_block_string_lines {
    my ($lines) = @_;

    if (ASSERT) {
        my $Lines = ReadonlyArray[Str];
        $Lines->assert_valid($lines);
    }

    my $common_indent = MAX_INTEGER;
    my $first_non_empty_line = undef;
    my $last_non_empty_line = -1;

    for (my $i = 0; $i < @$lines; ++$i) {
        my $line = $lines->[$i];
        my $indent = leading_whitespace($line);

        if ($indent == length($line)) {
            next; # skip empty lines
        }

        $first_non_empty_line //= $i;
        $last_non_empty_line = $i;

        if ($i != 0 && $indent < $common_indent) {
            $common_indent = $indent;
        }
    }

    # Remove common indentation from all lines but first.
    my @removed_indent_lines;
    for my $line (@$lines) {
        if (@removed_indent_lines == 0) {
            push @removed_indent_lines, $line;
        }
        else {
            push @removed_indent_lines, $common_indent < length($line) ? substr($line, $common_indent) : "";
        }
    }

    # Remove leading and trailing blank lines.
    my $result = [ @removed_indent_lines[$first_non_empty_line // 0 .. $last_non_empty_line] ];

    if (ASSERT) {
        my $Result = ArrayRef[Str];
        $Result->assert_valid($result);
    }

    return $result;
}

sub leading_whitespace {
    my ($str) = @_;
    my $i = 0;
    while ($i < length($str) && is_white_space(ord(substr($str, $i, 1)))) {
        ++$i;
    }
    return $i;
}

# @internal
sub is_printable_as_block_string {
    my ($value) = @_;

    if (length($value) == 0) {
        return 1; # empty string is printable
    }

    my $is_empty_line = 1;
    my $has_indent = 0;
    my $has_common_indent = 1;
    my $seen_non_empty_line = 0;

    for (my $i = 0; $i < length($value); ++$i) {
        my $char = substr($value, $i, 1);
        my $code_point = ord($char);

        if ($code_point == 0x0000 ||
            $code_point == 0x0001 ||
            $code_point == 0x0002 ||
            $code_point == 0x0003 ||
            $code_point == 0x0004 ||
            $code_point == 0x0005 ||
            $code_point == 0x0006 ||
            $code_point == 0x0007 ||
            $code_point == 0x0008 ||
            $code_point == 0x000b ||
            $code_point == 0x000c ||
            $code_point == 0x000e ||
            $code_point == 0x000f
        ) {
            return 0; # Has non-printable characters
        }
        elsif ($code_point == 0x000d) { # \r
            return 0; # Has \r or \r\n which will be replaced as \n
        }
        elsif ($code_point == 10) { # \n
            if ($is_empty_line && !$seen_non_empty_line) {
                return 0; # Has leading new line
            }

            $seen_non_empty_line = 1;

            $is_empty_line = 1;
            $has_indent = 0;
        }
        elsif ($code_point == 9 || $code_point == 32) { # \t or <space>
            $has_indent ||= $is_empty_line;
        }
        else {
            $has_common_indent &&= $has_indent;
            $is_empty_line = 0;
        }
    }

    if ($is_empty_line) {
        return 0; # Has trailing empty lines
    }

    if ($has_common_indent && $seen_non_empty_line) {
        return 0; # Has internal indent
    }

    return 1;
}

# Print a block string in the indented block form by adding a leading and
# trailing blank line. However, if a block string starts with whitespace and is
# a single-line, adding a leading blank line would strip that whitespace.
#
# @internal
sub print_block_string {
    my ($value, $options) = @_;
    $options //= {};

    if (ASSERT) {
        Str->assert_valid($value);
        my $Options = Dict[minimize => Optional[Bool]];
        $Options->assert_valid($options);
    }

    my $escaped_value = $value =~ s/"""/\\"""/gr;

    # Expand a block string's raw value into independent lines.
    my $lines = [ split /\r\n|[\n\r]/, $escaped_value ];
    my $is_single_line = @$lines == 1;

    # If common indentation is found we can fix some of those cases by adding leading new line
    my $force_leading_new_line =
        @$lines > 1 &&
        all { length($_) == 0 || is_white_space(ord(substr($_, 0, 1))) } @$lines[1 .. $#$lines];

    # Trailing triple quotes just looks confusing but doesn't force trailing new line
    my $has_trailing_triple_quotes = $escaped_value =~ /\\\"""$/;

    # Trailing quote (single or double) or slash forces trailing new line
    my $has_trailing_quote = $value =~ /"$/ && !$has_trailing_triple_quotes;
    my $has_trailing_slash = $value =~ /\\$/;
    my $force_trailing_newline = $has_trailing_quote || $has_trailing_slash;

    my $print_as_multiple_lines =
        !$options->{minimize} &&
        # add leading and trailing new lines only if it improves readability
        (!$is_single_line ||
            length($value) > 70 ||
            $force_trailing_newline ||
            $force_leading_new_line ||
            $has_trailing_triple_quotes);

    my $result = '';

    # Format a multi-line block quote to account for leading space.
    my $skip_leading_new_line = $is_single_line && is_white_space(ord(substr($value, 0, 1)));
    if (($print_as_multiple_lines && !$skip_leading_new_line) || $force_leading_new_line) {
        $result .= "\n";
    }

    $result .= $escaped_value;

    if ($print_as_multiple_lines || $force_trailing_newline) {
        $result .= "\n";
    }

    return '"""' . $result . '"""';
}

1;
