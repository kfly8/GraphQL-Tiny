use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{GRAPHQL_TINY_ASSERT} = 1;
}

use GraphQL::Tiny::Language::Source qw(Source build_source is_Source);

subtest 'Source' => sub {
    isa_ok Source, 'Type::Tiny';
    is Source->display_name, 'Source';
};

subtest 'build_source' => sub {
    subtest 'default' => sub {
        my $source = build_source('my body');

        is $source->{body}, 'my body';
        is $source->{name}, 'GraphQL request';
        is $source->{locationOffset}{line}, 1;
        is $source->{locationOffset}{column}, 1;
    };

    subtest 'set location_offset' => sub {
        my $source = build_source('my body', 'my name',
            {
                line => 123,
                column => 456,
            },
        );

        is $source->{body}, 'my body';
        is $source->{name}, 'my name';
        is $source->{locationOffset}{line}, 123;
        is $source->{locationOffset}{column}, 456;
    };

    subtest 'rejects invalid locationOffset' => sub {
        {
            eval { build_source('', '', { line => 0, column => 1 }) };
            like $@->{message}, qr/^line in locationOffset is 1-indexed and must be positive./
        }

        {
            eval { build_source('', '', { line => -1, column => 1 }) };
            like $@->{message}, qr/^line in locationOffset is 1-indexed and must be positive./
        }

        {
            eval { build_source('', '', { line => 1, column => 0 }) };
            like $@->{message}, qr/^column in locationOffset is 1-indexed and must be positive./
        }

        {
            eval { build_source('', '', { line => 1, column => -1 }) };
            like $@->{message}, qr/^column in locationOffset is 1-indexed and must be positive./
        }
    };
};

subtest 'is_Source' => sub {
    my $source = build_source('my body', 'my name');
    ok is_Source($source);
    ok !is_Source('');
};

done_testing;
