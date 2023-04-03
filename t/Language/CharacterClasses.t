use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::CharacterClasses qw(
  is_white_space
  is_digit
  is_letter
  is_name_start
  is_name_continue
);

subtest 'is_white_space' => sub {
    ok is_white_space(0x0009), 'should return true for horizontal tab (U+0009)';
    ok is_white_space(0x0020), 'should return true for space (U+0020)';

    ok !is_white_space(0x0008), 'should return false for backspace (U+0008)';
    ok !is_white_space(0x000A), 'should return false for line feed (U+000A)';
    ok !is_white_space(0x001F), 'should return false for unit separator (U+001F)';
    ok !is_white_space(0x0021), 'should return false for exclamation mark (U+0021)';
};

subtest 'is_digit' => sub {
    ok is_digit(0x0030), 'should return true for 0 (U+0030)';
    ok is_digit(0x0031), 'should return true for 1 (U+0031)';
    ok is_digit(0x0039), 'should return true for 9 (U+0039)';

    ok !is_digit(0x002F), 'should return false for slash (U+002F)';
    ok !is_digit(0x003A), 'should return false for colon (U+003A)';
};

subtest 'is_letter' => sub {
    ok is_letter(0x0041), 'should return true for A (U+0041)';
    ok is_letter(0x0042), 'should return true for B (U+0042)';
    ok is_letter(0x005A), 'should return true for Z (U+005A)';
    ok is_letter(0x0061), 'should return true for a (U+0061)';
    ok is_letter(0x0062), 'should return true for b (U+0062)';
    ok is_letter(0x007A), 'should return true for z (U+007A)';

    ok !is_letter(0x0040), 'should return false for @ (U+0040)';
    ok !is_letter(0x005B), 'should return false for [ (U+005B)';
    ok !is_letter(0x0060), 'should return false for ` (U+0060)';
    ok !is_letter(0x007B), 'should return false for { (U+007B)';
};

subtest 'is_name_start' => sub {
    ok is_name_start(0x0041), 'should return true for A (U+0041)';
    ok is_name_start(0x0042), 'should return true for B (U+0042)';
    ok is_name_start(0x005A), 'should return true for Z (U+005A)';
    ok is_name_start(0x0061), 'should return true for a (U+0061)';
    ok is_name_start(0x0062), 'should return true for b (U+0062)';
    ok is_name_start(0x007A), 'should return true for z (U+007A)';

    ok is_name_start(0x005F), 'should return true for _ (U+005F)';

    ok !is_name_start(0x0040), 'should return false for @ (U+0040)';
    ok !is_name_start(0x005B), 'should return false for [ (U+005B)';
    ok !is_name_start(0x0060), 'should return false for ` (U+0060)';
    ok !is_name_start(0x007B), 'should return false for { (U+007B)';
};

subtest 'is_name_continue' => sub {
    ok is_name_continue(0x0041), 'should return true for A (U+0041)';
    ok is_name_continue(0x0042), 'should return true for B (U+0042)';
    ok is_name_continue(0x005A), 'should return true for Z (U+005A)';
    ok is_name_continue(0x0061), 'should return true for a (U+0061)';
    ok is_name_continue(0x0062), 'should return true for b (U+0062)';
    ok is_name_continue(0x007A), 'should return true for z (U+007A)';

    ok is_name_continue(0x005F), 'should return true for _ (U+005F)';
    ok is_name_continue(0x0030), 'should return true for 0 (U+0030)';
    ok is_name_continue(0x0031), 'should return true for 1 (U+0031)';
    ok is_name_continue(0x0039), 'should return true for 9 (U+0039)';

    ok !is_name_continue(0x0040), 'should return false for @ (U+0040)';
    ok !is_name_continue(0x005B), 'should return false for [ (U+005B)';
    ok !is_name_continue(0x0060), 'should return false for ` (U+0060)';
    ok !is_name_continue(0x007B), 'should return false for { (U+007B)';
};

done_testing;
