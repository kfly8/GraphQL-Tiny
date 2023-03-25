use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Source qw(Source build_Source is_Source);

subtest 'Source' => sub {
    isa_ok Source, 'Type::Tiny';
};

subtest 'build_Source' => sub {
    subtest 'default' => sub {
        my $source = build_Source(
            body => 'my body',
            name => 'my name',
        );

        is $source->{body}, 'my body';
        is $source->{name}, 'my name';
        is $source->{location_offset}{line}, 1;
        is $source->{location_offset}{column}, 1;
    };

    subtest 'set location_offset' => sub {
        my $source = build_Source(
            body => 'my body',
            name => 'my name',
            location_offset => {
                line => 123,
                column => 456,
            },
        );

        is $source->{body}, 'my body';
        is $source->{name}, 'my name';
        is $source->{location_offset}{line}, 123;
        is $source->{location_offset}{column}, 456;
    };
};

subtest 'is_Source' => sub {
    my $source = build_Source(body => 'foo', name => 'bar');
    ok is_Source($source);
    ok !is_Source({ body => 'foo' });
};

done_testing;
