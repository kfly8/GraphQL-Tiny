use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{GRAPHQL_TINY_ASSERT} = 1;
}

use GraphQL::Tiny::Language::Source qw(Source build_Source is_Source);

subtest 'Source' => sub {
    isa_ok Source, 'Type::Tiny';
    is Source->display_name, 'Source';
};

subtest 'build_Source' => sub {
    subtest 'default' => sub {
        my $source = build_Source('my body');

        is $source->{body}, 'my body';
        is $source->{name}, 'GraphQL request';
        is $source->{location_offset}{line}, 1;
        is $source->{location_offset}{column}, 1;
    };

    subtest 'set location_offset' => sub {
        my $source = build_Source('my body', 'my name',
            {
                line => 123,
                column => 456,
            },
        );

        is $source->{body}, 'my body';
        is $source->{name}, 'my name';
        is $source->{location_offset}{line}, 123;
        is $source->{location_offset}{column}, 456;
    };

    subtest 'rejects invalid locationOffset' => sub {
        {
            eval { build_Source('', '', { line => 0, column => 1 }) };
            like $@, qr/^line in locationOffset is 1-indexed and must be positive./
        }

        {
            eval { build_Source('', '', { line => -1, column => 1 }) };
            like $@, qr/^line in locationOffset is 1-indexed and must be positive./
        }

        {
            eval { build_Source('', '', { line => 1, column => 0 }) };
            like $@, qr/^column in locationOffset is 1-indexed and must be positive./
        }

        {
            eval { build_Source('', '', { line => 1, column => -1 }) };
            like $@, qr/^column in locationOffset is 1-indexed and must be positive./
        }
    };
};

subtest 'is_Source' => sub {
    my $source = build_Source('my body', 'my name');
    ok is_Source($source);
    ok !is_Source('');
};

done_testing;
