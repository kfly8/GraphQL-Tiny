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

subtest 'add_path' => sub {
    my $path = add_path(undef, 'first', 'Hoge');

    note 'test $path';
    is $path->{prev}, undef;
    is $path->{key}, 'first';
    is $path->{typename}, 'Hoge';

    my $next_path = add_path($path, 'second', 'Fuga');

    note 'test $next_path';
    is $next_path->{prev}, $path;
    is $next_path->{key}, 'second';
    is $next_path->{typename}, 'Fuga';
};

subtest 'path_to_array' => sub {
    my $path = add_path(undef, 'first', 'Hoge');
    my $next_path = add_path($path, 'second', 'Fuga');

    my $array = path_to_array($next_path);
    is scalar @$array, 2;
    is $array->[0], 'first';
    is $array->[1], 'second';
};

done_testing;
