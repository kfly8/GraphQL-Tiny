use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::PrintString qw(print_string);

subtest 'print_string' => sub {
    subtest 'it prints a simple string' => sub {
        is print_string(qq!hello world!), qq!"hello world"!;
    };

    subtest 'it escapes quotes' => sub {
        is print_string(qq!"hello world"!), qq!"\\"hello world\\""!;
    };

    subtest 'it does not escape single quote' => sub {
        is print_string(qq!who's test!), qq!"who's test"!;
    };

    subtest 'it escapes backslashes' => sub {
        is print_string(qq!escape: \\!), qq!"escape: \\\\"!;
    };

    subtest 'it escapes well-known control chars' => sub {
        is print_string(qq!\b\f\n\r\t!), qq!"\\b\\f\\n\\r\\t"!;
    };

    subtest 'it escapes zero byte' => sub {
        is print_string(qq!\x00!), qq!"\\u0000"!;
    };

    subtest 'it does not escape space' => sub {
        is print_string(qq! !), qq!" "!;
    };

    subtest 'it does not escape non-ascii character' => sub {
        is print_string(qq!\x{21BB}!), qq!"\x{21BB}"!;
    };

    subtest 'it does not escape supplementary character' => sub {
        is print_string(qq!\x{1f600}!), qq!"\x{1f600}"!;
    };

    subtest 'it escapes all control chars' => sub {
        is print_string(
          qq!\x{0000}\x{0001}\x{0002}\x{0003}\x{0004}\x{0005}\x{0006}\x{0007}! .
          qq!\x{0008}\x{0009}\x{000A}\x{000B}\x{000C}\x{000D}\x{000E}\x{000F}! .
          qq!\x{0010}\x{0011}\x{0012}\x{0013}\x{0014}\x{0015}\x{0016}\x{0017}! .
          qq!\x{0018}\x{0019}\x{001A}\x{001B}\x{001C}\x{001D}\x{001E}\x{001F}! .
          qq!\x{0020}\x{0021}\x{0022}\x{0023}\x{0024}\x{0025}\x{0026}\x{0027}! .
          qq!\x{0028}\x{0029}\x{002A}\x{002B}\x{002C}\x{002D}\x{002E}\x{002F}! .
          qq!\x{0030}\x{0031}\x{0032}\x{0033}\x{0034}\x{0035}\x{0036}\x{0037}! .
          qq!\x{0038}\x{0039}\x{003A}\x{003B}\x{003C}\x{003D}\x{003E}\x{003F}! .
          qq!\x{0040}\x{0041}\x{0042}\x{0043}\x{0044}\x{0045}\x{0046}\x{0047}! .
          qq!\x{0048}\x{0049}\x{004A}\x{004B}\x{004C}\x{004D}\x{004E}\x{004F}! .
          qq!\x{0050}\x{0051}\x{0052}\x{0053}\x{0054}\x{0055}\x{0056}\x{0057}! .
          qq!\x{0058}\x{0059}\x{005A}\x{005B}\x{005C}\x{005D}\x{005E}\x{005F}! .
          qq!\x{0060}\x{0061}\x{0062}\x{0063}\x{0064}\x{0065}\x{0066}\x{0067}! .
          qq!\x{0068}\x{0069}\x{006A}\x{006B}\x{006C}\x{006D}\x{006E}\x{006F}! .
          qq!\x{0070}\x{0071}\x{0072}\x{0073}\x{0074}\x{0075}\x{0076}\x{0077}! .
          qq!\x{0078}\x{0079}\x{007A}\x{007B}\x{007C}\x{007D}\x{007E}\x{007F}! .
          qq!\x{0080}\x{0081}\x{0082}\x{0083}\x{0084}\x{0085}\x{0086}\x{0087}! .
          qq!\x{0088}\x{0089}\x{008A}\x{008B}\x{008C}\x{008D}\x{008E}\x{008F}! .
          qq!\x{0090}\x{0091}\x{0092}\x{0093}\x{0094}\x{0095}\x{0096}\x{0097}! .
          qq!\x{0098}\x{0099}\x{009A}\x{009B}\x{009C}\x{009D}\x{009E}\x{009F}!,
        ),
          '"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007' .
          '\\b\\t\\n\\u000B\\f\\r\\u000E\\u000F' .
          '\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017' .
          '\\u0018\\u0019\\u001A\\u001B\\u001C\\u001D\\u001E\\u001F' .
          ' !\\"#$%&\'()*+,-./0123456789:;<=>?' .
          '@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_' .
          '`abcdefghijklmnopqrstuvwxyz{|}~\\u007F' .
          '\\u0080\\u0081\\u0082\\u0083\\u0084\\u0085\\u0086\\u0087' .
          '\\u0088\\u0089\\u008A\\u008B\\u008C\\u008D\\u008E\\u008F' .
          '\\u0090\\u0091\\u0092\\u0093\\u0094\\u0095\\u0096\\u0097' .
          '\\u0098\\u0099\\u009A\\u009B\\u009C\\u009D\\u009E\\u009F"',
        ;
    };
};

done_testing;
