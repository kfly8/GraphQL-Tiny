package GraphQL::Tiny::Language::Ast;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type;

use Exporter 'import';

our @EXPORT_OK = qw(
    Token
    build_Token

    Location
    build_Location

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

use GraphQL::Tiny::Language::Kinds qw(Kind);
use GraphQL::Tiny::Language::Source qw(Source);
use GraphQL::Tiny::Language::TokenKind qw(TokenKind);


# Represents a range of characters represented by a lexical token
# within a Source.
use constant Token => do {
    my $BaseToken = type 'BaseToken', as Dict[
        # The kind of Token.
        kind => TokenKind,

        # The character offset at which this Node begins.
        start => Int,

        # The character offset at which this Node ends.
        end => Int,

        # The 1-indexed line number on which this Token appears.
        line => Int,

        # The 1-indexed column number at which this Token begins.
        column => Int,

        # For non-punctuation tokens, represents the interpreted value of the token.
        #
        # Note => is undefined for punctuation tokens, but typed as string for
        # convenience in the parser.
        value => Str,

        # Tokens exist as nodes in a double-linked-list amongst all tokens
        # including ignored tokens. <SOF> is always the first node and <EOF>
        # the last.
        prev => HashRef | Null,
        next => HashRef | Null,
    ];

    my $PrevToken;
    $PrevToken = type 'PrevToken', as $BaseToken & sub {
        return 0 if defined $_->{prev} && !$PrevToken->check($_->{prev});
        return 0 if defined $_->{next} && !$BaseToken->check($_->{next});
        return 1;
    };

    my $NextToken;
    $NextToken = type 'NextToken', as $BaseToken & sub {
        return 0 if defined $_->{prev} && !$BaseToken->check($_->{prev});
        return 0 if defined $_->{next} && !$NextToken->check($_->{next});
        return 1;
    };

    my $Token = type 'Token', as $BaseToken & Dict[
        prev => $PrevToken | Null,
        next => $NextToken | Null,
        Slurpy[Any]
    ];

    $Token;
};

sub build_Token {
    my ($kind, $start, $end, $line, $column, $value) = @_;
    my $token = {};
    $token->{kind} = $kind;
    $token->{start} = $start;
    $token->{end} = $end;
    $token->{line} = $line;
    $token->{column} = $column;
    $token->{value} = $value; # TODO(port): Non-null assertion operator
    $token->{prev} = undef;
    $token->{next} = undef;

    if (ASSERT) {
        Token->assert_valid($token);
    }

    return $token;
}

# Contains a range of UTF-8 character offsets and token references that
# identify the region of the source from which the AST derived.
use constant Location =>
    type 'Location',
    as Dict[
        # The character offset at which this Node begins.
        start => Int,

        # The character offset at which this Node ends.
        end => Int,

        # The Token at which this Node begins.
        start_token => Token,

        # The Token at which this Node ends.
        end_token => Token,

        # The Source document the AST represents.
        source => Source,
    ];

sub build_Location {
    my ($start_token, $end_token, $source) = @_;

    if (ASSERT) {
        Token->assert_valid($start_token);
        Token->assert_valid($end_token);
        Source->assert_valid($source);
    }

    my $location = {};
    $location->{start} = $start_token->{start};
    $location->{end} = $end_token->{end};
    $location->{start_token} = $start_token;
    $location->{end_token} = $end_token;
    $location->{source} = $source;
    return $location;
}

# The list of all possible AST node types.
use constant ASTNode =>
  type 'ASTNode',
  as NameNode
  | DocumentNode
  | OperationDefinitionNode
  | VariableDefinitionNode
  | VariableNode
  | SelectionSetNode
  | FieldNode
  | ArgumentNode
  | FragmentSpreadNode
  | InlineFragmentNode
  | FragmentDefinitionNode
  | IntValueNode
  | FloatValueNode
  | StringValueNode
  | BooleanValueNode
  | NullValueNode
  | EnumValueNode
  | ListValueNode
  | ObjectValueNode
  | ObjectFieldNode
  | DirectiveNode
  | NamedTypeNode
  | ListTypeNode
  | NonNullTypeNode
  | SchemaDefinitionNode
  | OperationTypeDefinitionNode
  | ScalarTypeDefinitionNode
  | ObjectTypeDefinitionNode
  | FieldDefinitionNode
  | InputValueDefinitionNode
  | InterfaceTypeDefinitionNode
  | UnionTypeDefinitionNode
  | EnumTypeDefinitionNode
  | EnumValueDefinitionNode
  | InputObjectTypeDefinitionNode
  | DirectiveDefinitionNode
  | SchemaExtensionNode
  | ScalarTypeExtensionNode
  | ObjectTypeExtensionNode
  | InterfaceTypeExtensionNode
  | UnionTypeExtensionNode
  | EnumTypeExtensionNode
  | InputObjectTypeExtensionNode
  | NonNullAssertionNode
  | ErrorBoundaryNode
  | ListNullabilityOperatorNode;

# Utility type listing all nodes indexed by their kind.
use constant ASTKindToNode => do {

    my @dict;
    for my $Node (@{$ASTNode->type_constraints}) {
        my $Kind = $Node->parent->parameters->[1];
        my $key = $Kind->parameters->[0];

        push @dict => (KIND->{$key}, $Node);
    }

    type 'ASTKindToNode', as Dict[@dict];
};

# TODO(port):
#
# @internal
#export const QueryDocumentKeys: {
#  [NodeT in ASTNode as NodeT['kind']]: ReadonlyArray<keyof NodeT>;
#} = {
#  Name: [],
#
#  Document: ['definitions'],
#  OperationDefinition: [
#    'name',
#    'variableDefinitions',
#    'directives',
#    'selectionSet',
#  ],
#  VariableDefinition: ['variable', 'type', 'defaultValue', 'directives'],
#  Variable: ['name'],
#  SelectionSet: ['selections'],
#  Field: [
#    'alias',
#    'name',
#    'arguments',
#    'directives',
#    'selectionSet',
#    // Note: Client Controlled Nullability is experimental and may be changed
#    // or removed in the future.
#    'nullabilityAssertion',
#  ],
#  Argument: ['name', 'value'],
#  // Note: Client Controlled Nullability is experimental and may be changed
#  // or removed in the future.
#  ListNullabilityOperator: ['nullabilityAssertion'],
#  NonNullAssertion: ['nullabilityAssertion'],
#  ErrorBoundary: ['nullabilityAssertion'],
#
#  FragmentSpread: ['name', 'directives'],
#  InlineFragment: ['typeCondition', 'directives', 'selectionSet'],
#  FragmentDefinition: [
#    'name',
#    // Note: fragment variable definitions are deprecated and will removed in v17.0.0
#    'variableDefinitions',
#    'typeCondition',
#    'directives',
#    'selectionSet',
#  ],
#
#  IntValue: [],
#  FloatValue: [],
#  StringValue: [],
#  BooleanValue: [],
#  NullValue: [],
#  EnumValue: [],
#  ListValue: ['values'],
#  ObjectValue: ['fields'],
#  ObjectField: ['name', 'value'],
#
#  Directive: ['name', 'arguments'],
#
#  NamedType: ['name'],
#  ListType: ['type'],
#  NonNullType: ['type'],
#
#  SchemaDefinition: ['description', 'directives', 'operationTypes'],
#  OperationTypeDefinition: ['type'],
#
#  ScalarTypeDefinition: ['description', 'name', 'directives'],
#  ObjectTypeDefinition: [
#    'description',
#    'name',
#    'interfaces',
#    'directives',
#    'fields',
#  ],
#  FieldDefinition: ['description', 'name', 'arguments', 'type', 'directives'],
#  InputValueDefinition: [
#    'description',
#    'name',
#    'type',
#    'defaultValue',
#    'directives',
#  ],
#  InterfaceTypeDefinition: [
#    'description',
#    'name',
#    'interfaces',
#    'directives',
#    'fields',
#  ],
#  UnionTypeDefinition: ['description', 'name', 'directives', 'types'],
#  EnumTypeDefinition: ['description', 'name', 'directives', 'values'],
#  EnumValueDefinition: ['description', 'name', 'directives'],
#  InputObjectTypeDefinition: ['description', 'name', 'directives', 'fields'],
#
#  DirectiveDefinition: ['description', 'name', 'arguments', 'locations'],
#
#  SchemaExtension: ['directives', 'operationTypes'],
#
#  ScalarTypeExtension: ['name', 'directives'],
#  ObjectTypeExtension: ['name', 'interfaces', 'directives', 'fields'],
#  InterfaceTypeExtension: ['name', 'interfaces', 'directives', 'fields'],
#  UnionTypeExtension: ['name', 'directives', 'types'],
#  EnumTypeExtension: ['name', 'directives', 'values'],
#  InputObjectTypeExtension: ['name', 'directives', 'fields'],
#};

# TODO(port)
# const kindValues = new Set<string>(Object.keys(QueryDocumentKeys));

# TODO(port)
# @internal
# export function isNode(maybeNode: any): maybeNode is ASTNode {
#   const maybeKind = maybeNode?.kind;
#   return typeof maybeKind === 'string' && kindValues.has(maybeKind);
# }


# Name
use constant NameNode =>
    type 'NameNode',
    as Dict[
        kind => Kind['NAME'],
        loc => Optional[ Location | Undef ],
        value => Str,
    ];

# Document
use constant DocumentNode =>
    type 'DocumentNode',
    as Dict[
        kind => Kind['DOCUMENT'],
        loc => Optional[ Location | Undef ],
        definitions => ReadonlyArray[DefinitionNode],
    ];

use constant DefinitionNode =>
    type 'DefinitionNode',
    as ExecutableDefinitionNode
     | TypeSystemDefinitionNode
     | TypeSystemExtensionNode;

use constant ExecutableDefinitionNode =>
    type 'ExecutableDefinitionNode',
    as OperationDefinitionNode
     | FragmentDefinitionNode;

use constant OperationDefinitionNode =>
    type 'OperationDefinitionNode',
    as Dict[
        kind => Kind['OPERATION_DEFINITION'],
        loc => Optional[ Location | Undef ],
        operation => OperationTypeNode,
        name => Optional[ NameNode | Undef ],
        variableDefinitions => Optional[ ReadonlyArray[VariableDefinitionNode] | Undef ],
        directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
        selection_set => SelectionSetNode
    ;

use constant OPERATION_TYPE_NODE => {
    QUERY => 'query',
    MUTATION => 'mutation',
    SUBSCRIPTION => 'subscription',
};

use constant OperationTypeNode =>
    type 'OperationTypeNode',
    as Enum[ values %{ OPERATION_TYPE_NODE() } ];

use constant VariableDefinitionNode =>
    type 'VariableDefinitionNode',
    as Dict[
        kind => Kind['VARIABLE_DEFINITION'],
        loc => Optional[ Location | Undef ],
        variable => VariableNode,
        type => TypeNode,
        default_value => Optional[ ConstValueNode | Undef ],
        directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

use constant VariableNode =>
    type 'VariableNode',
    as Dict[
        kind => Kind['VARIABLE'],
        loc => Optional[ Location | Undef ],
        name => NameNode,
    ];

use constant SelectionSetNode =>
    type 'SelectionSetNode',
    as Dict[
        kind => Kind['SELECTION_SET'],
        loc => Optional[ Location | Undef ],
        selections => ReadonlyArray[SelectionNode],
    ];

use constant SelectionNode =>
    type 'SelectionNode', as FieldNode | FragmentSpreadNode | InlineFragmentNode;

use constant FieldNode =>
    type 'FieldNode',
    as Dict[
        kind => Kind['FIELD'],
        loc => Optional[ Location | Undef ],
        alias => Optional[ NameNode | Undef ],
        name => NameNode,
        arguments => Optional[ReadonlyArray[ArgumentNode] | Undef],
        # Note: Client Controlled Nullability is experimental
        # and may be changed or removed in the future.
        nullability_assertion => Optional[ NullabilityAssertionNode | Undef ],
        directives => Optional[ ReadonlyArray<DirectiveNode> | Undef ],
        selectionSet => Optional[ SelectionSetNode | Undef ],
    ];

use constant NullabilityAssertionNode =>
    type 'NullabilityAssertionNode',
    as NonNullAssertionNode
     | ErrorBoundaryNode
     | ListNullabilityOperatorNode;

use constant ListNullabilityOperatorNode =>
    type 'ListNullabilityOperatorNode',
    as Dict[
        kind => Kind['LIST_NULLABILITY_OPERATOR'],
        loc => Optional[ Location | Undef ],
        nullability_assertion => Optional[ NullabilityAssertionNode | Undef ],
    ];

use constant NonNullAssertionNode =>
    type 'NonNullAssertionNode',
    as Dict[
        kind => Kind['NON_NULL_ASSERTION'],
        loc => Optional[ Location | Undef ],
        nullability_assertion => Optional[ ListNullabilityOperatorNode | Undef ],
    ];

use constant ErrorBoundaryNode =>
    type 'ErrorBoundaryNode',
    as Dict[
       kind => Kind['ERROR_BOUNDARY'],
       loc => Optional[ Location | Undef ],
       nullability_assertion => Optional[ ListNullabilityOperatorNode | Undef ],
    ];

use constant ArgumentNode =>
    type 'ArgumentNode',
    as Dict[
       kind => Kind['ARGUMENT'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ValueNode,
   ];

use constant ConstArgumentNode =>
    type 'ConstArgumentNode',
    as Dict[
       kind => Kind['ARGUMENT'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ConstValueNode,
    ];

# Fragments

use constant FragmentSpreadNode =>
    type 'FragmentSpreadNode',
    as Dict[
       kind => Kind['FRAGMENT_SPREAD'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
    ];

use constant InlineFragmentNode =>
    type 'InlineFragmentNode',
    as Dict[
       kind => Kind['FRAGMENT_SPREAD'],
       loc => Optional[ Location | Undef ],
       type_conditions => Optional[ NamedTypeNode | Undef ],
       directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
       selection_set => SelectionSetNode,
    ];

use constant FragmentDefinitionNode =>
    type 'FragmentDefinitionNode',
    as Dict[
       kind => Kind['FRAGMENT_DEFINITION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,

       # @deprecated variableDefinitions will be removed in v17.0.0 */
       variable_definitions => Optional[ ReadonlyArray[VariableDefinitionNode] | Undef ],
       type_condition => NamedTypeNode,
       directives => Optional[ ReadonlyArray<DirectiveNode> | Undef ],
       selection_set => SelectionSetNode,
    ];

# Values

use constant ValueNode =>
    type 'ValueNode',
    as VariableNode
     | IntValueNode
     | FloatValueNode
     | StringValueNode
     | BooleanValueNode
     | NullValueNode
     | EnumValueNode
     | ListValueNode
     | ObjectValueNode;

use constant ConstValueNode =>
    type 'ConstValueNode',
    as IntValueNode
     | FloatValueNode
     | StringValueNode
     | BooleanValueNode
     | NullValueNode
     | EnumValueNode
     | ConstListValueNode
     | ConstObjectValueNode;

use constant IntValueNode =>
    type 'IntValueNode',
    as Dict[
       kind => Kind['INT'],
       loc => Optional[ Location | Undef ],
       value => Str,
    ];

use constant FloatValueNode =>
    type 'FloatValueNode',
    as Dict[
       kind => Kind['FLOAT'],
       loc => Optional[ Location | Undef ],
       value => Str,
    ];

use constant StringValueNode =>
    type 'StringValueNode',
    as Dict[
       kind => Kind['STRING'],
       loc => Optional[ Location | Undef ],
       value => Str,
       block => Optional[ Bool | Undef ],
    ];

use constant BooleanValueNode =>
    type 'BooleanValueNode',
    as Dict[
       kind => Kind['BOOLEAN'],
       loc => Optional[ Location | Undef ],
       value => Bool,
    ];

use constant NullValueNode =>
    type 'NullValueNode',
    as Dict[
       kind => Kind['NULL'],
       loc => Optional[ Location | Undef ],
    ];

use constant EnumValueNode =>
    type 'EnumValueNode',
    as Dict[
       kind => Kind['ENUM'],
       loc => Optional[ Location | Undef ],
       value => Str,
    ];

use constant ListValueNode =>
    type 'ListValueNode',
    as Dict[
       kind => Kind['LIST'],
       loc => Optional[ Location | Undef ],
       value => ReadonlyArray[ValueNode],
    ];

use constant ConstListValueNode =>
    type 'ConstListValueNode',
    as Dict[
       kind => Kind['LIST'],
       loc => Optional[ Location | Undef ],
       value => ReadonlyArray[ConstValueNode],
    ];

use constant ObjectValueNode =>
    type 'ObjectValueNode',
    as Dict[
       kind => Kind['OBJECT'],
       loc => Optional[ Location | Undef ],
       value => ReadonlyArray[ObjectFieldNode],
    ];

use constant ConstObjectValueNode =>
    type 'ConstObjectValueNode',
    as Dict[
       kind => Kind['OBJECT'],
       loc => Optional[ Location | Undef ],
       value => ReadonlyArray[ConstObjectFieldNode],
    ];

use constant ObjectFieldNode =>
    type 'ObjectFieldNode',
    as Dict[
       kind => Kind['OBJECT_FIELD'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ValueNode,
    ];

use constant ConstObjectFieldNode =>
    type 'ConstObjectFieldNode',
    as Dict[
       kind => Kind['OBJECT_FIELD'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ConstValueNode,
    ];

# Directives

use constant DirectiveNode =>
    type 'DirectiveNode',
    as Dict[
       kind => Kind['DIRECTIVE'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       arguments => Optional[ ReadonlyArray[ArgumentNode] | Undef ],
    ];

use constant ConstDirectiveNode =>
    type 'ConstDirectiveNode',
    as Dict[
       kind => Kind['DIRECTIVE'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       arguments => Optional[ ReadonlyArray[ConstArgumentNode] | Undef ],
    ];

# Type Reference

use constant TypeNode =>
    type 'TypeNode', as NamedTypeNode | ListTypeNode | NonNullTypeNode;

use constant NamedTypeNode =>
    type 'NamedTypeNode',
    as Dict[
       kind => Kind['NAMED_TYPE'],
       loc => Optional[ Location | Undef ],
       name => NameNode,

use constant ListTypeNode =>
    type 'ListTypeNode',
    as Dict[
       kind => Kind['LIST_TYPE'],
       loc => Optional[ Location | Undef ],
       type => TypeNode,
   ];

use constant NonNullTypeNode =>
    type 'NonNullTypeNode',
    as Dict[
       kind => Kind['NON_NULL_TYPE'],
       loc => Optional[ Location | Undef ],
       type => NamedTypeNode | ListTypeNode,
   ];

# Type System Definition

use constant TypeSystemDefinitionNode =>
    type 'TypeSystemDefinitionNode',
    as SchemaDefinitionNode
     | TypeDefinitionNode
     | DirectiveDefinitionNode;

use constant SchemaDefinitionNode =>
    type 'SchemaDefinitionNode',
    as Dict[
       kind => Kind['SCHEMA_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       operation_types => ReadonlyArray[OperationTypeDefinitionNode],
   ];

use constant OperationTypeDefinitionNode =>
    type 'OperationTypeDefinitionNode',
    as Dict[
       kind => Kind['OPERATION_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       operation => OperationTypeNode,
       type => NamedTypeNode,
    ];

# Type Definition

use constant TypeDefinitionNode =>
    type 'TypeDefinitionNode',
    as ScalarTypeDefinitionNode
     | ObjectTypeDefinitionNode
     | InterfaceTypeDefinitionNode
     | UnionTypeDefinitionNode
     | EnumTypeDefinitionNode
     | InputObjectTypeDefinitionNode;

use constant ScalarTypeDefinitionNode =>
    type 'ScalarTypeDefinitionNode',
    as Dict[
       kind => Kind['SCALAR_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

use constant ObjectTypeDefinitionNode =>
    type 'ObjectTypeDefinitionNode',
    as Dict[
       kind => Kind['OBJECT_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode] | Undef ],
    ];

use constant FieldDefinitionNode =>
    type 'FieldDefinitionNode',
    as Dict[
       kind => Kind['FIELD_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       arguments => Optional[ ReadonlyArray[InputValueDefinitionNode] | Undef ],
       type => TypeNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];


use constant InputValueDefinitionNode =>
    type 'InputValueDefinitionNode',
    as Dict[
       kind => Kind['INPUT_VALUE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       type => TypeNode,
       default_value => Optional[ ConstValueNode | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

use constant InterfaceTypeDefinitionNode =>
    type 'InterfaceTypeDefinitionNode',
    as Dict[
       kind => Kind['INTERFACE_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       interfaces => Optional[ ReadonlyArray[NamedTypeNode] | Undef],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode | Undef ],
    ];


use constant UnionTypeDefinitionNode =>
    type 'UnionTypeDefinitionNode',
    as Dict[
       kind => Kind['UNION_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       types => Optional[ ReadonlyArray[NamedTypeNode] | Undef ],
    ];

use constant EnumTypeDefinitionNode =>
    type 'EnumTypeDefinitionNode',
    as Dict[
       kind => Kind['ENUM_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       values => Optional[ ReadonlyArray[EnumValueDefinitionNode] | Undef ],
    ];

use constant EnumValueDefinitionNode =>
    type 'EnumValueDefinitionNode',
    as Dict[
       kind => Kind['ENUM_VALUE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

use constant InputObjectTypeDefinitionNode =>
    type 'InputObjectTypeDefinitionNode',
    as Dict[
       kind => Kind['INPUT_OBJECT_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       fields => Optional[ ReadonlyArray[InputValueDefinitionNode] | Undef ],
    ];

# Directive Definitions

use constant DirectiveDefinitionNode =>
    type 'DirectiveDefinitionNode',
    as Dict[
       kind => Kind['DIRECTIVE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       arguments => Optional[ ReadonlyArray[InputValueDefinitionNode] | Undef],
       repeatable => Bool,
       locations => ReadonlyArray[NameNode],
    ];

# Type System Extensions

use constant TypeSystemExtensionNode =>
    type 'TypeSystemExtensionNode', as SchemaExtensionNode | TypeExtensionNode

use constant SchemaExtensionNode =>
    type 'SchemaExtensionNode',
    as Dict[
       kind => Kind['SCHEMA_EXTENSION'],
       loc => Optional[ Location | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       operation_types => Optional[ ReadonlyArray[OperationTypeDefinitionNode] | Undef ],

# Type Extensions

use constant TypeExtensionNode =>
    type 'TypeExtensionNode',
    as ScalarTypeExtensionNode
     | ObjectTypeExtensionNode
     | InterfaceTypeExtensionNode
     | UnionTypeExtensionNode
     | EnumTypeExtensionNode
     | InputObjectTypeExtensionNode;

use constant ScalarTypeExtensionNode =>
    type 'ScalarTypeExtensionNode',
    as Dict[
       kind => Kind['SCALAR_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
    ];

use constant ObjectTypeExtensionNode =>
    type 'ObjectTypeExtensionNode',
    as Dict[
       kind => Kind['OBJECT_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       interfaces => Optional[ ReadonlyArray[NamedTypeNode] | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode] | Undef],
    ];

use constant InterfaceTypeExtensionNode =>
    type 'InterfaceTypeExtensionNode',
    as Dict[
       kind => Kind['INTERFACE_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       interfaces => Optional[ ReadonlyArray[NamedTypeNode] | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode] | Undef],
    ];

use constant UnionTypeExtensionNode =>
    type 'UnionTypeExtensionNode',
    as Dict[
       kind => Kind['UNION_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       types => Optional[ ReadonlyArray[NamedTypeNode] | Undef],
    ];

use constant EnumTypeExtensionNode =>
    type 'EnumTypeExtensionNode',
    as Dict[
       kind => Kind['ENUM_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       values => Optional[ ReadonlyArray[EnumValueDefinitionNode] | Undef],
    ];

use constant InputObjectTypeExtensionNode =>
    type 'InputObjectTypeExtensionNode',
    as Dict[
       kind => Kind['INPUT_OBJECT_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       fields => Optional[ ReadonlyArray[InputValueDefinitionNode] | Undef],
    ];

1;
