use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Kinds qw(KIND Kind);

subtest 'Kind' => sub {
    isa_ok Kind, 'Type::Tiny';
    is Kind->display_name, 'Kind';

    ok Kind->check('Name');
    ok !Kind->check('Namee');
};

subtest 'KIND' => sub {
    ok KIND->{NAME}, 'Name';
};

done_testing;
