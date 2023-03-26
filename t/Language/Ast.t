use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Source qw(build_source);

my @nodes = qw(
    ASTNode
    NameNode
    DocumentNode
    DefinitionNode
    ExecutableDefinitionNode
    OperationDefinitionNode
    OperationTypeNode
    VariableDefinitionNode
    VariableNode
    SelectionSetNode
    SelectionNode
    FieldNode
    NullabilityAssertionNode
    ListNullabilityOperatorNode
    NonNullAssertionNode
    ErrorBoundaryNode
    ArgumentNode
    ConstArgumentNode
    FragmentSpreadNode
    InlineFragmentNode
    FragmentDefinitionNode
    ValueNode
    ConstValueNode
    IntValueNode
    FloatValueNode
    StringValueNode
    BooleanValueNode
    NullValueNode
    EnumValueNode
    ListValueNode
    ConstListValueNode
    ObjectValueNode
    ConstObjectValueNode
    ObjectFieldNode
    ConstObjectFieldNode
    DirectiveNode
    ConstDirectiveNode
    TypeNode
    NamedTypeNode
    ListTypeNode
    NonNullTypeNode
    TypeSystemDefinitionNode
    SchemaDefinitionNode
    OperationTypeDefinitionNode
    TypeDefinitionNode
    ScalarTypeDefinitionNode
    ObjectTypeDefinitionNode
    FieldDefinitionNode
    InputValueDefinitionNode
    InterfaceTypeDefinitionNode
    UnionTypeDefinitionNode
    EnumTypeDefinitionNode
    EnumValueDefinitionNode
    InputObjectTypeDefinitionNode
    DirectiveDefinitionNode
    TypeSystemExtensionNode
    SchemaExtensionNode
    TypeExtensionNode
    ScalarTypeExtensionNode
    ObjectTypeExtensionNode
    InterfaceTypeExtensionNode
    UnionTypeExtensionNode
    EnumTypeExtensionNode
    InputObjectTypeExtensionNode
);

use GraphQL::Tiny::Language::Ast (
    qw(Token build_token Location build_location),
);

use GraphQL::Tiny::Language::Ast -types;

subtest 'Token' => sub {
    isa_ok Token, 'Type::Tiny';
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
};

subtest 'build_location' => sub {
    my $start_token = build_token('Name', 1, 2, 123, 456, 'start');
    my $end_token = build_token('Name', 2, 3, 234, 567, 'end');
    my $source = build_source('body');

    my $location = build_location($start_token, $end_token, $source);
    is $location->{start}, 1;
    is $location->{end}, 3;
    is $location->{start_token}, $start_token;
    is $location->{end_token}, $end_token;
    is $location->{source}, $source;
};

subtest 'ASTKindToNode' => sub {
    isa_ok ASTKindToNode, 'Type::Tiny';
    ok ASTKindToNode->is_strictly_subtype_of('Dict');
};

subtest 'ASTNodes' => sub {
    for my $name (@nodes) {
        my $code = __PACKAGE__->can($name);
        is $code->()->display_name, $name, $name;
    }
};

done_testing;
