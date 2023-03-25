package GraphQL::Tiny::Language::Kinds;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(Kind);

use Types::Common -types;
use Type::Utils;

# The set of allowed kind values for AST nodes.
use constant Kind =>
    declare 'Kind',
    as Enum[
    # Name
    'Name',

    # Document
    'Document',
    'OperationDefinition',
    'VariableDefinition',
    'SelectionSet',
    'Field',
    'Argument',

    # Nullability Modifiers
    'ListNullabilityOperator',
    'NonNullAssertion',
    'ErrorBoundary',

    # Fragments
    'FragmentSpread',
    'InlineFragment',
    'FragmentDefinition',

    # Values
    'Variable',
    'IntValue',
    'FloatValue',
    'StringValue',
    'BooleanValue',
    'NullValue',
    'EnumValue',
    'ListValue',
    'ObjectValue',
    'ObjectField',

    # Directives
    'Directive',

    # Types
    'NamedType',
    'ListType',
    'NonNullType',

    # Type System Definitions
    'SchemaDefinition',
    'OperationTypeDefinition',

    # Type Definitions
    'ScalarTypeDefinition',
    'ObjectTypeDefinition',
    'FieldDefinition',
    'InputValueDefinition',
    'InterfaceTypeDefinition',
    'UnionTypeDefinition',
    'EnumTypeDefinition',
    'EnumValueDefinition',
    'InputObjectTypeDefinition',

    # Directive Definitions
    'DirectiveDefinition',

    # Type System Extensions
    'SchemaExtension',

    # Type Extensions
    'ScalarTypeExtension',
    'ObjectTypeExtension',
    'InterfaceTypeExtension',
    'UnionTypeExtension',
    'EnumTypeExtension',
    'InputObjectTypeExtension',
];

1;
