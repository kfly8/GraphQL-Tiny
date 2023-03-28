use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Invariant qw(invariant);

local $@;
eval {invariant(1, 'success') };
is $@, '';

eval { invariant(0, 'fail') };
my $error = $@;
ok $error->{name};
is $error->{message}, 'fail';
ok $error->{stack};

done_testing;
