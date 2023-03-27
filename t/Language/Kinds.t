use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Kinds qw(KIND Kind);

subtest 'Kind' => sub {
    subtest 'no argument' => sub {
        isa_ok Kind, 'Type::Tiny';
        is Kind->display_name, 'Kind';

        ok Kind->check('Name');
        ok Kind->check('Document');
        ok !Kind->check('Namee');
    };

    subtest 'kind key is given' => sub {
        my $Type = Kind['NAME'];
        isa_ok $Type, 'Type::Tiny';
        is $Type->display_name, 'Kind_NAME';
        is $Type->parent, 'Enum["Name"]';

        ok $Type->check('Name');
        ok !$Type->check('Document');
        ok !$Type->check('Namee');
    };

    subtest 'invalid kind key is given' => sub {
        eval { Kind['Name'] };
        like $@, qr/Cannot find kind: Name/
    };
};

subtest 'KIND' => sub {
    ok KIND->{NAME}, 'Name';
};

done_testing;
