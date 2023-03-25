use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Kinds qw(Kind);

isa_ok Kind, 'Type::Tiny::Enum';

ok Kind->check('Name');
ok !Kind->check('Namee');

done_testing;
