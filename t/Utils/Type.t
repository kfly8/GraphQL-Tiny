use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Type -all;

subtest 'type and as' => sub {
    my $Type = type 'Foo', as Any;

    isa_ok $Type, 'Type::Tiny';
    is $Type->display_name, 'Foo';
    ok $Type->is_strictly_subtype_of(Any);
};

subtest 'Error' => sub {
    isa_ok Error, 'Type::Tiny';
    is Error->display_name, 'Error';
    my $Dict = Error->parent;
    my %params = @{$Dict->parameters};

    ok $params{name};
    ok $params{message};
    ok $params{stack};

    ok Error->check({name => 'RangeError', message => 'The argument must be an "apple"', stack => '...'});

    subtest 'Error type can be extended.' => sub {
        my $Type = Error & Dict[myinfo => Str, Slurpy[Any]];

        ok $Type->check(
            {
                name => 'MyError',
                message => 'some message',
                stack => '...',
                myinfo => 'hello!',
            }
        );
    };
};

subtest 'Null' => sub {
    isa_ok Null, 'Type::Tiny';
    is Null->display_name, 'Null';
    ok Null->is_strictly_subtype_of(Undef);
    ok Null->check(undef);
    ok !Null->check(1);
};

subtest 'Unknown' => sub {
    isa_ok Unknown, 'Type::Tiny';
    is Unknown->display_name, 'Unknown';
    ok Unknown->is_strictly_subtype_of(Any);
    ok Unknown->check(1);
};

subtest 'ReadonlyArray' => sub {
    my $Type = ReadonlyArray[Str];
    isa_ok $Type, 'Type::Tiny';

    is $Type->display_name, 'ReadonlyArray[Str]';
    ok $Type->is_strictly_subtype_of('ArrayRef');
    ok $Type->check([1,2,3]);
};

done_testing;
