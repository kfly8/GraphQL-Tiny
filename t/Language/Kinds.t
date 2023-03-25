use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Kinds qw(Kind);

subtest 'Kind' => sub {
    isa_ok Kind, 'Type::Tiny';
    is Kind->display_name, 'Kind';

    ok Kind->check('Name');
    ok !Kind->check('Namee');
};

done_testing;
