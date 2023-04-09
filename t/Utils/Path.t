use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Path qw(Path add_path path_to_array);

subtest 'Path' => sub {
    isa_ok Path, 'Type::Tiny';
    is Path->display_name, 'Path';

    my $path = {
        prev => undef,
        key => 'first',
        typename => 'Hoge',
    };

    ok Path->check($path);
    ok !Path->check({ prev => undef, key => 'first' });
};

subtest 'it can create a Path' => sub {
    my $first = add_path(undef, 1, 'First');

    is $first->{prev}, undef;
    is $first->{key}, 1;
    is $first->{typename}, 'First';
};

subtest 'it can add a new key to an existing Path' => sub {
    my $first = add_path(undef, 1, 'First');
    my $second = add_path($first, 'two', 'Second');

    is $second->{prev}, $first;
    is $second->{key}, 'two';
    is $second->{typename}, 'Second';
};

subtest 'it can convert a Path to an array of its keys' => sub {
    my $root = add_path(undef, 0, 'Root');
    my $first = add_path($root, 'one', 'First');
    my $second = add_path($first, 2, 'Second');

    my $path = path_to_array($second);
    is scalar @$path, 3;
    is $path->[0], 0;
    is $path->[1], 'one';
    is $path->[2], 2;
};

done_testing;
