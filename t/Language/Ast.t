use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Source qw(build_Source);

use GraphQL::Tiny::Language::Ast qw(
    Token
    build_Token
    Location
    build_Location
);

subtest 'Token' => sub {
    isa_ok Token, 'Type::Tiny';
};

subtest 'build_Token' => sub {
    my $token = build_Token('Name', 1, 2, 123, 456, 'value');

    is $token->{kind}, 'Name';
    is $token->{start}, '1';
    is $token->{end}, '2';
    is $token->{line}, '123';
    is $token->{column}, '456';
    is $token->{value}, 'value';
};

subtest 'Location' => sub {
    isa_ok Location, 'Type::Tiny';
};

subtest 'build_Location' => sub {
    my $start_token = build_Token('Name', 1, 2, 123, 456, 'start');
    my $end_token = build_Token('Name', 2, 3, 234, 567, 'end');
    my $source = build_Source('body');

    my $location = build_Location($start_token, $end_token, $source);
    is $location->{start}, 1;
    is $location->{end}, 3;
    is $location->{start_token}, $start_token;
    is $location->{end_token}, $end_token;
    is $location->{source}, $source;
};

done_testing;
