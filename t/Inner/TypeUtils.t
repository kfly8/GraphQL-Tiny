use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Inner::TypeUtils qw(
    type
    as
    where
    constraints_of_union
    values_of_enum
    value_of_enum
    parameters_of_dict
    key_of_dict
);

use Types::Standard qw(Any Str Int Enum Dict ArrayRef);

subtest 'type and as' => sub {
    my $Type = type 'Foo', as Any;

    isa_ok $Type, 'Type::Tiny';
    is $Type->display_name, 'Foo';
    ok $Type->is_strictly_subtype_of(Any);
};

subtest 'constraints_of_union' => sub {
    is_deeply constraints_of_union(Str | Int), [Str, Int], 'anonymous union';

    my $Union = type 'MyUnion', as Str | Int;
    is_deeply constraints_of_union($Union), [Str, Int], 'named union';

    eval { constraints_of_union(Str) };
    ok $@, 'not union';
};

subtest 'values_of_enum' => sub {
    is_deeply values_of_enum(Enum['foo', 'bar']), ['foo', 'bar'], 'anonymous enum';

    my $Enum = type 'MyEnum', as Enum['foo', 'bar'];
    is_deeply values_of_enum($Enum), ['foo', 'bar'], 'named enum';

    eval { values_of_enum(Str) };
    ok $@, 'not enum';
};

subtest 'value_of_enum' => sub {
    is_deeply value_of_enum(Enum['foo', 'bar']), 'foo', 'anonymous enum';

    my $Enum = type 'MyEnum2', as Enum['foo', 'bar'];
    is_deeply value_of_enum($Enum), 'foo', 'named enum';

    eval { value_of_enum(Str) };
    ok $@, 'not enum';
};

subtest 'parameters_of_dict' => sub {
    my $Dict = Dict[foo => Str, bar => Int];
    is_deeply parameters_of_dict($Dict), ['foo', Str, 'bar', Int], 'anonymous dict';

    my $Dict2 = type 'MyDict', as Dict[foo => Str, bar => Int];
    is_deeply parameters_of_dict($Dict2), ['foo', Str, 'bar', Int], 'named dict';

    eval { parameters_of_dict(ArrayRef[Str]) };
    ok $@, 'not dict';

    subtest 'given a key' => sub {
        is parameters_of_dict($Dict, 'foo'), Str, 'foo type isa Str';
        is parameters_of_dict($Dict, 'bar'), Int, 'bar type isa Int';

        local $@;
        eval { parameters_of_dict($Dict, 'baz') };
        ok $@;
    };
};

subtest 'key_of_dict' => sub {
    my $Dict = Dict[foo => Str, bar => Int];
    is key_of_dict($Dict), Enum['foo', 'bar'], 'anonymous dict';

    my $Dict2 = type 'MyDict2', as Dict[foo => Str, bar => Int];
    is key_of_dict($Dict2), Enum['foo', 'bar'], 'named dict';

    eval { key_of_dict(ArrayRef[Str]) };
    ok $@, 'not dict';
};

done_testing;
