use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Source qw(build_source);
use GraphQL::Tiny::Language::Location qw(SourceLocation get_location);

subtest 'SourceLocation' => sub {
    isa_ok SourceLocation, 'Type::Tiny';
    is SourceLocation, 'SourceLocation';

    my $Dict = SourceLocation->parent;
    my %params = @{$Dict->parameters};
    ok $params{line};
    ok $params{column};
};

subtest 'get_location' => sub {
    my $source = build_source(<<QUERY);
query {
  foo
  bar
}
QUERY

    my @test_cases = (
        { position => 0,  expected => { line => 1, column => 1 } },
        { position => 7,  expected => { line => 1, column => 8 } },
        { position => 8,  expected => { line => 2, column => 1 } },
        { position => 12,  expected => { line => 2, column => 5 } },
        { position => 13,  expected => { line => 2, column => 6 } },
        { position => 14,  expected => { line => 3, column => 1 } },
    );

    for my $test_case (@test_cases) {
        my $got = get_location($source, $test_case->{position});
        subtest "get_location as position: @{[$test_case->{position}]}" => sub {
            is $got->{line}, $test_case->{expected}->{line};
            is $got->{column}, $test_case->{expected}->{column};
        };
    }
};

done_testing;
