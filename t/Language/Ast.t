use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Type -all;
use GraphQL::Tiny::Language::Source qw(build_source);

use GraphQL::Tiny::Language::Ast qw(
    Token build_token Location build_location
    ASTNode ASTKindToNode
    NameNode DocumentNode
    QueryDocumentKeys
    is_Node
);

use GraphQL::Tiny::Language::Ast -types;

subtest 'Token' => sub {
    isa_ok Token, 'Type::Tiny';
    ok Token->parent->is_strictly_subtype_of('Dict');
    is Token, 'Token';
};

subtest 'build_token' => sub {
    my $token = build_token('Name', 1, 2, 123, 456, 'value');

    is $token->{kind}, 'Name';
    is $token->{start}, '1';
    is $token->{end}, '2';
    is $token->{line}, '123';
    is $token->{column}, '456';
    is $token->{value}, 'value';
};

subtest 'Location' => sub {
    isa_ok Location, 'Type::Tiny';
    ok Location->parent->is_strictly_subtype_of('Dict');
    is Location, 'Location';
};

subtest 'build_location' => sub {
    my $start_token = build_token('Name', 1, 2, 123, 456, 'start');
    my $end_token = build_token('Name', 2, 3, 234, 567, 'end');
    my $source = build_source('body');

    my $location = build_location($start_token, $end_token, $source);
    is $location->{start}, 1;
    is $location->{end}, 3;
    is $location->{startToken}, $start_token;
    is $location->{endToken}, $end_token;
    is $location->{source}, $source;
};

subtest 'ASTNode' => sub {
    isa_ok ASTNode, 'Type::Tiny';
    isa_ok ASTNode->parent, 'Type::Tiny::Union';
    is ASTNode, 'ASTNode';
};

subtest 'ASTKindToNode' => sub {
    isa_ok ASTKindToNode, 'Type::Tiny';
    ok ASTKindToNode->is_strictly_subtype_of('Dict');

    my %params = @{ASTKindToNode->parent->parameters};
    is $params{Name}, NameNode;
    is $params{Document}, DocumentNode;
};

subtest 'QueryDocumentKeys' => sub {

    # { [NodeT in ASTNode as NodeT['kind']]: ReadonlyArray<keyof NodeT>; }
    for my $Node (@{ASTNode->parent->type_constraints}) {
        my $Type = ASTNode->library->get_type($Node);

        my @params = @{$Type->parent->parameters};
        my %params = @params;

        my $Kind = $params{kind};
        my $key = $Kind->parent->values->[0];

        my @node_keys;
        for (my $i = 0; $i < @params; $i += 2) {
            push @node_keys => $params[$i];
        }

        my $KeyofNode = ReadonlyArray[ Enum[@node_keys] ];
        ok($KeyofNode->check(QueryDocumentKeys->{$key}), $key)
            or note explain $KeyofNode->validate(QueryDocumentKeys->{$key});
    }
};

subtest 'is_Node' => sub {
    ok is_Node({ kind => 'Name', value => 'foo' }), 'NameNode is Node';
    ok is_Node({ kind => 'Variable', value => 'bar' }), 'VariableNode is Node';

    ok !is_Node({ kind => 'Nameee', value => 'foo' }), 'NameeeNode is NOT Node';
};

done_testing;
