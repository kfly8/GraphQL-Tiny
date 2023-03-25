use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Kinds qw(Kind);

isa_ok Kind, 'Type::Tiny::Enum';

done_testing;
