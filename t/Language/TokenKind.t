use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::TokenKind qw(TOKEN_KIND TokenKind);

isa_ok TokenKind, 'Type::Tiny';

my $amp = '&';
ok TokenKind->check($amp);
ok !TokenKind->check('foo');

is TOKEN_KIND->{AMP}, $amp;

done_testing;
