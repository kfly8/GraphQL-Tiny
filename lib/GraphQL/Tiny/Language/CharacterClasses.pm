package GraphQL::Tiny::Type::CharacterClasses;
use strict;
use warnings;

our @EXPORT_OK = qw(
  is_white_space
  is_digit
  is_letter
  is_name_start
  is_name_continue
);

# ```
# WhiteSpace ::
#   - "Horizontal Tab (U+0009)"
#   - "Space (U+0020)"
# ```
# @internal
sub is_white_space {
    my ($code) = @_;
    return $code == 0x0009 || $code == 0x0020;
}

# ```
# Digit :: one of
#   - `0` `1` `2` `3` `4` `5` `6` `7` `8` `9`
# ```
# @internal
sub is_digit {
    my ($code) = @_;
    return $code >= 0x0030 && $code <= 0x0039;
}

# ```
# Letter :: one of
#   - `A` `B` `C` `D` `E` `F` `G` `H` `I` `J` `K` `L` `M`
#   - `N` `O` `P` `Q` `R` `S` `T` `U` `V` `W` `X` `Y` `Z`
#   - `a` `b` `c` `d` `e` `f` `g` `h` `i` `j` `k` `l` `m`
#   - `n` `o` `p` `q` `r` `s` `t` `u` `v` `w` `x` `y` `z`
# ```
# @internal
sub is_letter {
    my ($code) = @_;
    return (
        ($code >= 0x0061 && $code <= 0x007a) || # A-Z
        ($code >= 0x0041 && $code <= 0x005a) # a-z
    );
}

# ```
# NameStart ::
#   - Letter
#   - `_`
# ```
# @internal
sub is_name_start {
    my ($code) = @_;
    return is_letter($code) || $code == 0x005f;
}

# ```
# NameContinue ::
#   - Letter
#   - Digit
#   - `_`
# ```
# @internal
sub is_name_continue {
    my ($code) = @_;
    return is_letter($code) || is_digit($code) || $code == 0x005f;
}

1;
