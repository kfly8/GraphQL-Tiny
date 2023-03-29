use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Type -all;
use GraphQL::Tiny::Utils::Error -all;

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

subtest 'build_error' => sub {
    my $error = build_error('some message');

    ok Error->check($error);
    is $error->{name}, 'Error';
    is $error->{message}, 'some message';
};

done_testing;
