use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::TokenKind qw(TokenKind);

subtest 'TOkenKind' => sub {
    isa_ok TokenKind, 'Type::Tiny';

    my $amp = '&';
    ok TokenKind->check($amp);
    ok !TokenKind->check('foo');
};

done_testing;
