use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Invariant qw(invariant);
use GraphQL::Tiny::Utils::Error qw(Error);

local $@;
eval {invariant(1, 'success') };
is $@, '';

eval { invariant(0, 'fail') };
my $error = $@;
ok Error->check($error);
is $error->{message}, 'fail';

done_testing;
