use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Inner::TypeLibrary qw(Any Dict Slurpy Str);
use GraphQL::Tiny::Utils::Error qw(Error build_error to_error);

subtest 'Error' => sub {
    isa_ok Error, 'Type::Tiny';
    is Error->display_name, 'Error';
    my $Dict = Error->parent;
    my %params = @{$Dict->parameters}[0..5];

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

subtest 'to_error' => sub  {

    subtest 'Error argument is given' => sub {
        my $error = to_error(build_error('some_message'));

        ok Error->check($error);
        is $error->{name}, 'Error';
        is $error->{message}, 'some_message';
    };

    subtest 'Unkown argument is given' => sub {
        my $error = to_error({ error => 'some message' });

        ok Error->check($error);
        is $error->{name}, 'NonErrorThrown';
        is $error->{message}, "Unexpected error value: {'error' => 'some message'}";
        is $error->{thrown_value}->{error}, 'some message';
    };
};

done_testing;
