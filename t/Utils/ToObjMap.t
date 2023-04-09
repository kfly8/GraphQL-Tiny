use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::ToObjMap qw(to_obj_map);

subtest 'to_obj_map' => sub {
    subtest 'it convert undefined to ObjMap' => sub {
        my $result = to_obj_map(undef);
        is_deeply $result, {};
    };

    subtest 'it convert empty object to ObjMap' => sub {
        my $result = to_obj_map({});
        is_deeply $result, {};
    };

    subtest 'it convert object with own properties to ObjMap' => sub {
        my $obj = { foo => 'bar' };
        my $result = to_obj_map($obj);
        is_deeply $result, $obj;
    };
};

done_testing;
