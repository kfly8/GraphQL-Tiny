use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::BlockString qw(
    dedent_block_string_lines
    is_printable_as_block_string
    print_block_string
);

sub join_lines {
    return join "\n", @_;
}

subtest 'dedent_block_string_lines' => sub {
    subtest 'it handles empty string' => sub {
        is_deeply dedent_block_string_lines([""]), [];
    };

    subtest 'it does not dedent first line' => sub {
        is_deeply dedent_block_string_lines(["  a"]), ["  a"];
        is_deeply dedent_block_string_lines([" a", "  b"]), [" a", "b"];
    };

    subtest 'it removes minimal indentation length' => sub {
        is_deeply dedent_block_string_lines(["", " a", "  b"]), ["a", " b"];
        is_deeply dedent_block_string_lines(["", "  a", " b"]), [" a", "b"];
        is_deeply dedent_block_string_lines(["", "  a", " b", "c"]), ["  a", " b", "c"];
    };

    subtest 'it dedent both tab and space as single character' => sub {
        is_deeply dedent_block_string_lines(["", "\ta", "          b"]), ["a", "         b"];
        is_deeply dedent_block_string_lines(["", "\t a", "          b"]), ["a", "        b"];
        is_deeply dedent_block_string_lines(["", " \t a", "          b"]), ["a", "       b"];
    };

    subtest 'it dedent do not take empty lines into account' => sub {
        is_deeply dedent_block_string_lines(["a", "", " b"]), ["a", "", "b"];
        is_deeply dedent_block_string_lines(["a", " ", "  b"]), ["a", "", "b"];
    };

    subtest 'it removes uniform indentation from a string' => sub {
        my $lines = [
            "",
            "    Hello,",
            "      World!",
            "",
            "    Yours,",
            "      GraphQL.",
        ];

        is_deeply dedent_block_string_lines($lines), [
            "Hello,",
            "  World!",
            "",
            "Yours,",
            "  GraphQL.",
        ];
    };

    subtest 'it removes empty leading and trailing lines' => sub {
        my $lines = [
            "",
            "",
            "    Hello,",
            "      World!",
            "",
            "    Yours,",
            "      GraphQL.",
            "",
            "",
        ];

        is_deeply dedent_block_string_lines($lines), [
            "Hello,",
            "  World!",
            "",
            "Yours,",
            "  GraphQL.",
        ];
    };

    subtest 'it removes blank leading and trailing lines' => sub {
        my $lines = [
            "  ",
            "        ",
            "    Hello,",
            "      World!",
            "",
            "    Yours,",
            "      GraphQL.",
            "        ",
            "  ",
        ];

        is_deeply dedent_block_string_lines($lines), [
            "Hello,",
            "  World!",
            "",
            "Yours,",
            "  GraphQL.",
        ];
    };

    subtest 'it retains indentation from first line' => sub {
        my $lines = [
            "    Hello,",
            "      World!",
            "",
            "    Yours,",
            "      GraphQL.",
        ];

        is_deeply dedent_block_string_lines($lines), [
            "    Hello,",
            "  World!",
            "",
            "Yours,",
            "  GraphQL.",
        ];
    };

    subtest 'it does not alter trailing spaces' => sub {
        my $lines = [
            "               ",
            "    Hello,     ",
            "      World!   ",
            "               ",
            "    Yours,     ",
            "      GraphQL. ",
            "               ",
        ];

        is_deeply dedent_block_string_lines($lines), [
            "Hello,     ",
            "  World!   ",
            "           ",
            "Yours,     ",
            "  GraphQL. ",
        ];
    };
};

subtest 'is_printable_as_block_string' => sub {
    subtest 'it accepts valid strings' => sub {
        ok is_printable_as_block_string('');
        ok is_printable_as_block_string(' a');
        ok is_printable_as_block_string("\t\"\n\"");
        ok !is_printable_as_block_string("\t\"\n \n\t\"");
    };

    subtest 'it rejects strings with only whitespace' => sub {
        ok !is_printable_as_block_string(' ');
        ok !is_printable_as_block_string("\t");
        ok !is_printable_as_block_string("\t ");
        ok !is_printable_as_block_string(" \t");
    };

    subtest 'it rejects strings with non-printable characters' => sub {
        ok !is_printable_as_block_string("\x00");
        ok !is_printable_as_block_string("a\x00b");
    };

    subtest 'it rejects strings with only empty lines' => sub {
        ok !is_printable_as_block_string("\n");
        ok !is_printable_as_block_string("\n\n");
        ok !is_printable_as_block_string("\n\n\n");
        ok !is_printable_as_block_string(" \n  \n");
        ok !is_printable_as_block_string("\t\n\t\t\n");
    };

    subtest 'it rejects strings with carriage return' => sub {
        ok !is_printable_as_block_string("\r");
        ok !is_printable_as_block_string("\n\r");
        ok !is_printable_as_block_string("\r\n");
        ok !is_printable_as_block_string("a\rb");
    };

    subtest 'it rejects strings with leading empty lines' => sub {
        ok !is_printable_as_block_string("\na");
        ok !is_printable_as_block_string(" \na");
        ok !is_printable_as_block_string("\t\na");
        ok !is_printable_as_block_string("\n\na");
    };

    subtest 'it rejects strings with trailing empty lines' => sub {
        ok !is_printable_as_block_string("a\n");
        ok !is_printable_as_block_string("a\n ");
        ok !is_printable_as_block_string("a\n\t");
        ok !is_printable_as_block_string("a\n\n");
    };
};

subtest 'print_block_string' => sub {
    subtest 'it does not escape characters' => sub {
        my $str = qq!" \\ / \b \f \n \r \t!;
        is print_block_string($str), qq!"""\n! . $str . qq!\n"""!;
        is print_block_string($str, { minimize => 1 }), qq!"""\n! . $str . qq!"""!;
    };

    subtest 'by default print block strings as single line' => sub {
        my $str = 'one liner';
        is print_block_string($str), qq!"""one liner"""!;
    };

    subtest 'by default print block strings ending with triple quotation as multi-line' => sub {
        my $str = 'triple quotation """';
        is print_block_string($str), qq!"""\ntriple quotation \\"""\n"""!;
        is print_block_string($str, { minimize => 1 }), qq!"""triple quotation \\""""""!;
    };

    subtest 'it correctly prints single-line with leading space' => sub {
        my $str = '    space-led string';
        is print_block_string($str), qq!"""    space-led string"""!;
    };

    subtest 'it correctly prints single-line with leading space and trailing quotation' => sub {
        my $str = '    space-led value "quoted string"';
        is print_block_string($str), qq!"""    space-led value "quoted string"\n"""!;
    };

    subtest 'it correctly prints single-line with trailing backslash' => sub {
        my $str = 'backslash \\';
        is print_block_string($str), qq!"""\nbackslash \\\n"""!;
        is print_block_string($str, { minimize => 1 }), qq!"""backslash \\\n"""!;
    };

    subtest 'it correctly prints multi-line with internal indent' => sub {
        my $str = "no indent\n with indent";
        is print_block_string($str), qq!"""\nno indent\n with indent\n"""!;
        is print_block_string($str, { minimize => 1 }), qq!"""\nno indent\n with indent"""!;
    };

    subtest 'it correctly prints string with a first line indentation' => sub {
        my $str = join_lines(
            '    first  ',
            '  line     ',
            'indentation',
            '     string',
        );

        is print_block_string($str), join_lines(
            '"""',
            '    first  ',
            '  line     ',
            'indentation',
            '     string',
            '"""',
        );

        is print_block_string($str, { minimize => 1 }), join_lines(
            '"""    first  ',
            '  line     ',
            'indentation',
            '     string"""',
        );
    };
};

done_testing;
