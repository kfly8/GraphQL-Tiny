package GraphQL::Tiny::Language::Ast;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type;

use GraphQL::Tiny::Language::Kinds qw(Kind KIND);

our @EXPORT_OK = qw(
    build_token
    build_location

    QueryDocumentKeys
    is_Node
);

use Type::Library -base, -declare => qw(
    Token
    Location

    ASTNode
    ASTKindToNode

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
type 'Token', do {
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

    as $BaseToken & Dict[
        prev => $PrevToken | Null,
        next => $NextToken | Null,
        Slurpy[Any]
    ];
};

sub build_token {
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
type 'Location',
    as Dict[
        # The character offset at which this Node begins.
        start => Int,

        # The character offset at which this Node ends.
        end => Int,

        # The Token at which this Node begins.
        startToken => Token,

        # The Token at which this Node ends.
        endToken => Token,

        # The Source document the AST represents.
        source => Source,
    ];

sub build_location {
    my ($start_token, $end_token, $source) = @_;

    if (ASSERT) {
        Token->assert_valid($start_token);
        Token->assert_valid($end_token);
        Source->assert_valid($source);
    }

    my $location = {};
    $location->{start} = $start_token->{start};
    $location->{end} = $end_token->{end};
    $location->{startToken} = $start_token;
    $location->{endToken} = $end_token;
    $location->{source} = $source;
    return $location;
}

# The list of all possible AST node types.
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

# @internal
# { [NodeT in ASTNode as NodeT['kind']]: ReadonlyArray<keyof NodeT>; }
use constant QueryDocumentKeys => {
  Name => [],

  Document => ['definitions'],
  OperationDefinition => [
    'name',
    'variableDefinitions',
    'directives',
    'selectionSet',
  ],
  VariableDefinition => ['variable', 'type', 'defaultValue', 'directives'],
  Variable => ['name'],
  SelectionSet => ['selections'],
  Field => [
    'alias',
    'name',
    'arguments',
    'directives',
    'selectionSet',
    # Note => Client Controlled Nullability is experimental and may be changed
    # or removed in the future.
    'nullabilityAssertion',
  ],
  Argument => ['name', 'value'],
  # Note => Client Controlled Nullability is experimental and may be changed
  # or removed in the future.
  ListNullabilityOperator => ['nullabilityAssertion'],
  NonNullAssertion => ['nullabilityAssertion'],
  ErrorBoundary => ['nullabilityAssertion'],

  FragmentSpread => ['name', 'directives'],
  InlineFragment => ['typeCondition', 'directives', 'selectionSet'],
  FragmentDefinition => [
    'name',
    # Note => fragment variable definitions are deprecated and will removed in v17.0.0
    'variableDefinitions',
    'typeCondition',
    'directives',
    'selectionSet',
  ],

  IntValue => [],
  FloatValue => [],
  StringValue => [],
  BooleanValue => [],
  NullValue => [],
  EnumValue => [],
  ListValue => ['values'],
  ObjectValue => ['fields'],
  ObjectField => ['name', 'value'],

  Directive => ['name', 'arguments'],

  NamedType => ['name'],
  ListType => ['type'],
  NonNullType => ['type'],

  SchemaDefinition => ['description', 'directives', 'operationTypes'],
  OperationTypeDefinition => ['type'],

  ScalarTypeDefinition => ['description', 'name', 'directives'],
  ObjectTypeDefinition => [
    'description',
    'name',
    'interfaces',
    'directives',
    'fields',
  ],
  FieldDefinition => ['description', 'name', 'arguments', 'type', 'directives'],
  InputValueDefinition => [
    'description',
    'name',
    'type',
    'defaultValue',
    'directives',
  ],
  InterfaceTypeDefinition => [
    'description',
    'name',
    'interfaces',
    'directives',
    'fields',
  ],
  UnionTypeDefinition => ['description', 'name', 'directives', 'types'],
  EnumTypeDefinition => ['description', 'name', 'directives', 'values'],
  EnumValueDefinition => ['description', 'name', 'directives'],
  InputObjectTypeDefinition => ['description', 'name', 'directives', 'fields'],

  DirectiveDefinition => ['description', 'name', 'arguments', 'locations'],

  SchemaExtension => ['directives', 'operationTypes'],

  ScalarTypeExtension => ['name', 'directives'],
  ObjectTypeExtension => ['name', 'interfaces', 'directives', 'fields'],
  InterfaceTypeExtension => ['name', 'interfaces', 'directives', 'fields'],
  UnionTypeExtension => ['name', 'directives', 'types'],
  EnumTypeExtension => ['name', 'directives', 'values'],
  InputObjectTypeExtension => ['name', 'directives', 'fields'],
};

#const kindValues = new Set<string>(Object.keys(QueryDocumentKeys));
my %KIND_VALUES = map { $_ => 1 } keys %{ QueryDocumentKeys() };

# @internal
sub is_Node {
    my ($maybe_node) = @_;
    my $maybe_kind = $maybe_node->{kind} // '';
    exists $KIND_VALUES{$maybe_kind};
}

# Name
type 'NameNode',
    as Dict[
        kind => Kind['NAME'],
        loc => Optional[ Location | Undef ],
        value => Str,
    ];

# Document
type 'DocumentNode',
    as Dict[
        kind => Kind['DOCUMENT'],
        loc => Optional[ Location | Undef ],
        definitions => ReadonlyArray[DefinitionNode],
    ];

type 'DefinitionNode',
    as ExecutableDefinitionNode
     | TypeSystemDefinitionNode
     | TypeSystemExtensionNode;

type 'ExecutableDefinitionNode',
    as OperationDefinitionNode
     | FragmentDefinitionNode;

type 'OperationDefinitionNode',
    as Dict[
        kind => Kind['OPERATION_DEFINITION'],
        loc => Optional[ Location | Undef ],
        operation => OperationTypeNode,
        name => Optional[ NameNode | Undef ],
        variableDefinitions => Optional[ ReadonlyArray[VariableDefinitionNode] | Undef ],
        directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
        selectionSet => SelectionSetNode
    ];

use constant OPERATION_TYPE_NODE => {
    QUERY => 'query',
    MUTATION => 'mutation',
    SUBSCRIPTION => 'subscription',
};

type 'OperationTypeNode',
    as Enum[ values %{ OPERATION_TYPE_NODE() } ];

type 'VariableDefinitionNode',
    as Dict[
        kind => Kind['VARIABLE_DEFINITION'],
        loc => Optional[ Location | Undef ],
        variable => VariableNode,
        type => TypeNode,
        defaultValue => Optional[ ConstValueNode | Undef ],
        directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

type 'VariableNode',
    as Dict[
        kind => Kind['VARIABLE'],
        loc => Optional[ Location | Undef ],
        name => NameNode,
    ];

type 'SelectionSetNode',
    as Dict[
        kind => Kind['SELECTION_SET'],
        loc => Optional[ Location | Undef ],
        selections => ReadonlyArray[SelectionNode],
    ];

type 'SelectionNode', as FieldNode | FragmentSpreadNode | InlineFragmentNode;

type 'FieldNode',
    as Dict[
        kind => Kind['FIELD'],
        loc => Optional[ Location | Undef ],
        alias => Optional[ NameNode | Undef ],
        name => NameNode,
        arguments => Optional[ReadonlyArray[ArgumentNode] | Undef],
        # Note: Client Controlled Nullability is experimental
        # and may be changed or removed in the future.
        nullabilityAssertion => Optional[ NullabilityAssertionNode | Undef ],
        directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
        selectionSet => Optional[ SelectionSetNode | Undef ],
    ];

type 'NullabilityAssertionNode',
    as NonNullAssertionNode
     | ErrorBoundaryNode
     | ListNullabilityOperatorNode;

type 'ListNullabilityOperatorNode',
    as Dict[
        kind => Kind['LIST_NULLABILITY_OPERATOR'],
        loc => Optional[ Location | Undef ],
        nullabilityAssertion => Optional[ NullabilityAssertionNode | Undef ],
    ];

type 'NonNullAssertionNode',
    as Dict[
        kind => Kind['NON_NULL_ASSERTION'],
        loc => Optional[ Location | Undef ],
        nullabilityAssertion => Optional[ ListNullabilityOperatorNode | Undef ],
    ];

type 'ErrorBoundaryNode',
    as Dict[
       kind => Kind['ERROR_BOUNDARY'],
       loc => Optional[ Location | Undef ],
       nullabilityAssertion => Optional[ ListNullabilityOperatorNode | Undef ],
    ];

type 'ArgumentNode',
    as Dict[
       kind => Kind['ARGUMENT'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ValueNode,
   ];

type 'ConstArgumentNode',
    as Dict[
       kind => Kind['ARGUMENT'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ConstValueNode,
    ];

# Fragments
type 'FragmentSpreadNode',
    as Dict[
       kind => Kind['FRAGMENT_SPREAD'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
    ];

type 'InlineFragmentNode',
    as Dict[
       kind => Kind['INLINE_FRAGMENT'],
       loc => Optional[ Location | Undef ],
       typeCondition => Optional[ NamedTypeNode | Undef ],
       directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
       selectionSet => SelectionSetNode,
    ];

type 'FragmentDefinitionNode',
    as Dict[
       kind => Kind['FRAGMENT_DEFINITION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,

       # @deprecated variableDefinitions will be removed in v17.0.0 */
       variableDefinitions => Optional[ ReadonlyArray[VariableDefinitionNode] | Undef ],
       typeCondition => NamedTypeNode,
       directives => Optional[ ReadonlyArray[DirectiveNode] | Undef ],
       selectionSet => SelectionSetNode,
    ];

# Values
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

type 'ConstValueNode',
    as IntValueNode
     | FloatValueNode
     | StringValueNode
     | BooleanValueNode
     | NullValueNode
     | EnumValueNode
     | ConstListValueNode
     | ConstObjectValueNode;

type 'IntValueNode',
    as Dict[
       kind => Kind['INT'],
       loc => Optional[ Location | Undef ],
       value => Str,
    ];

type 'FloatValueNode',
    as Dict[
       kind => Kind['FLOAT'],
       loc => Optional[ Location | Undef ],
       value => Str,
    ];

type 'StringValueNode',
    as Dict[
       kind => Kind['STRING'],
       loc => Optional[ Location | Undef ],
       value => Str,
       block => Optional[ Bool | Undef ],
    ];

type 'BooleanValueNode',
    as Dict[
       kind => Kind['BOOLEAN'],
       loc => Optional[ Location | Undef ],
       value => Bool,
    ];

type 'NullValueNode',
    as Dict[
       kind => Kind['NULL'],
       loc => Optional[ Location | Undef ],
    ];

type 'EnumValueNode',
    as Dict[
       kind => Kind['ENUM'],
       loc => Optional[ Location | Undef ],
       value => Str,
    ];

type 'ListValueNode',
    as Dict[
       kind => Kind['LIST'],
       loc => Optional[ Location | Undef ],
       values => ReadonlyArray[ValueNode],
    ];

type 'ConstListValueNode',
    as Dict[
       kind => Kind['LIST'],
       loc => Optional[ Location | Undef ],
       values => ReadonlyArray[ConstValueNode],
    ];

type 'ObjectValueNode',
    as Dict[
       kind => Kind['OBJECT'],
       loc => Optional[ Location | Undef ],
       fields => ReadonlyArray[ObjectFieldNode],
    ];

type 'ConstObjectValueNode',
    as Dict[
       kind => Kind['OBJECT'],
       loc => Optional[ Location | Undef ],
       fields => ReadonlyArray[ConstObjectFieldNode],
    ];

type 'ObjectFieldNode',
    as Dict[
       kind => Kind['OBJECT_FIELD'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ValueNode,
    ];

type 'ConstObjectFieldNode',
    as Dict[
       kind => Kind['OBJECT_FIELD'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       value => ConstValueNode,
    ];

# Directives
type 'DirectiveNode',
    as Dict[
       kind => Kind['DIRECTIVE'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       arguments => Optional[ ReadonlyArray[ArgumentNode] | Undef ],
    ];

type 'ConstDirectiveNode',
    as Dict[
       kind => Kind['DIRECTIVE'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       arguments => Optional[ ReadonlyArray[ConstArgumentNode] | Undef ],
    ];

# Type Reference
type 'TypeNode', as NamedTypeNode | ListTypeNode | NonNullTypeNode;

type 'NamedTypeNode',
    as Dict[
       kind => Kind['NAMED_TYPE'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
   ];

type 'ListTypeNode',
    as Dict[
       kind => Kind['LIST_TYPE'],
       loc => Optional[ Location | Undef ],
       type => TypeNode,
   ];

type 'NonNullTypeNode',
    as Dict[
       kind => Kind['NON_NULL_TYPE'],
       loc => Optional[ Location | Undef ],
       type => NamedTypeNode | ListTypeNode,
   ];

# Type System Definition
type 'TypeSystemDefinitionNode',
    as SchemaDefinitionNode
     | TypeDefinitionNode
     | DirectiveDefinitionNode;

type 'SchemaDefinitionNode',
    as Dict[
       kind => Kind['SCHEMA_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       operationTypes => ReadonlyArray[OperationTypeDefinitionNode],
   ];

type 'OperationTypeDefinitionNode',
    as Dict[
       kind => Kind['OPERATION_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       operation => OperationTypeNode,
       type => NamedTypeNode,
    ];

# Type Definition
type 'TypeDefinitionNode',
    as ScalarTypeDefinitionNode
     | ObjectTypeDefinitionNode
     | InterfaceTypeDefinitionNode
     | UnionTypeDefinitionNode
     | EnumTypeDefinitionNode
     | InputObjectTypeDefinitionNode;

type 'ScalarTypeDefinitionNode',
    as Dict[
       kind => Kind['SCALAR_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

type 'ObjectTypeDefinitionNode',
    as Dict[
       kind => Kind['OBJECT_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       interfaces => Optional[ ReadonlyArray[NamedTypeNode] | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode] | Undef ],
    ];

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


type 'InputValueDefinitionNode',
    as Dict[
       kind => Kind['INPUT_VALUE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       type => TypeNode,
       defaultValue => Optional[ ConstValueNode | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

type 'InterfaceTypeDefinitionNode',
    as Dict[
       kind => Kind['INTERFACE_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       interfaces => Optional[ ReadonlyArray[NamedTypeNode] | Undef],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode | Undef ] ],
    ];


type 'UnionTypeDefinitionNode',
    as Dict[
       kind => Kind['UNION_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       types => Optional[ ReadonlyArray[NamedTypeNode] | Undef ],
    ];

type 'EnumTypeDefinitionNode',
    as Dict[
       kind => Kind['ENUM_TYPE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
       values => Optional[ ReadonlyArray[EnumValueDefinitionNode] | Undef ],
    ];

type 'EnumValueDefinitionNode',
    as Dict[
       kind => Kind['ENUM_VALUE_DEFINITION'],
       loc => Optional[ Location | Undef ],
       description => Optional[ StringValueNode | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef ],
    ];

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
type 'TypeSystemExtensionNode', as SchemaExtensionNode | TypeExtensionNode

type 'SchemaExtensionNode',
    as Dict[
       kind => Kind['SCHEMA_EXTENSION'],
       loc => Optional[ Location | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       operationTypes => Optional[ ReadonlyArray[OperationTypeDefinitionNode] | Undef ],
   ];

# Type Extensions
type 'TypeExtensionNode',
    as ScalarTypeExtensionNode
     | ObjectTypeExtensionNode
     | InterfaceTypeExtensionNode
     | UnionTypeExtensionNode
     | EnumTypeExtensionNode
     | InputObjectTypeExtensionNode;

type 'ScalarTypeExtensionNode',
    as Dict[
       kind => Kind['SCALAR_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
    ];

type 'ObjectTypeExtensionNode',
    as Dict[
       kind => Kind['OBJECT_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       interfaces => Optional[ ReadonlyArray[NamedTypeNode] | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode] | Undef],
    ];

type 'InterfaceTypeExtensionNode',
    as Dict[
       kind => Kind['INTERFACE_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       interfaces => Optional[ ReadonlyArray[NamedTypeNode] | Undef ],
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       fields => Optional[ ReadonlyArray[FieldDefinitionNode] | Undef],
    ];

type 'UnionTypeExtensionNode',
    as Dict[
       kind => Kind['UNION_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       types => Optional[ ReadonlyArray[NamedTypeNode] | Undef],
    ];

type 'EnumTypeExtensionNode',
    as Dict[
       kind => Kind['ENUM_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       values => Optional[ ReadonlyArray[EnumValueDefinitionNode] | Undef],
    ];

type 'InputObjectTypeExtensionNode',
    as Dict[
       kind => Kind['INPUT_OBJECT_TYPE_EXTENSION'],
       loc => Optional[ Location | Undef ],
       name => NameNode,
       directives => Optional[ ReadonlyArray[ConstDirectiveNode] | Undef],
       fields => Optional[ ReadonlyArray[InputValueDefinitionNode] | Undef],
    ];


# Utility type listing all nodes indexed by their kind.
type 'ASTKindToNode', do {
    my @dict;
    for my $Node (@{ASTNode->parent->type_constraints}) {
        my $Type = __PACKAGE__->meta->get_type($Node);

        my %params = @{$Type->parent->parameters};
        my $Kind = $params{kind};
        my $key = $Kind->parent->values->[0];

        push @dict => ($key, $Node);
    }

    as Dict[@dict];
};

1;
