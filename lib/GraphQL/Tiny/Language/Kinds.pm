package GraphQL::Tiny::Language::Kinds;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeUtils qw(type as);
use GraphQL::Tiny::Inner::TypeLibrary qw(Enum);

use Carp qw(croak);
use Exporter 'import';

our @EXPORT_OK = qw(Kind);

# The set of allowed kind values for AST nodes.
my @KINDS = (
  # Name
  [ NAME => 'Name' ],

  # Document
  [ DOCUMENT => 'Document' ],
  [ OPERATION_DEFINITION => 'OperationDefinition' ],
  [ VARIABLE_DEFINITION => 'VariableDefinition' ],
  [ SELECTION_SET => 'SelectionSet' ],
  [ FIELD => 'Field' ],
  [ ARGUMENT => 'Argument' ],

  # Nullability Modifiers
  [ LIST_NULLABILITY_OPERATOR => 'ListNullabilityOperator' ],
  [ NON_NULL_ASSERTION => 'NonNullAssertion' ],
  [ ERROR_BOUNDARY => 'ErrorBoundary' ],

  # Fragments
  [ FRAGMENT_SPREAD => 'FragmentSpread' ],
  [ INLINE_FRAGMENT => 'InlineFragment' ],
  [ FRAGMENT_DEFINITION => 'FragmentDefinition' ],

  # Values
  [ VARIABLE => 'Variable' ],
  [ INT => 'IntValue' ],
  [ FLOAT => 'FloatValue' ],
  [ STRING => 'StringValue' ],
  [ BOOLEAN => 'BooleanValue' ],
  [ NULL => 'NullValue' ],
  [ ENUM => 'EnumValue' ],
  [ LIST => 'ListValue' ],
  [ OBJECT => 'ObjectValue' ],
  [ OBJECT_FIELD => 'ObjectField' ],

  # Directives
  [ DIRECTIVE => 'Directive' ],

  # Types
  [ NAMED_TYPE => 'NamedType' ],
  [ LIST_TYPE => 'ListType' ],
  [ NON_NULL_TYPE => 'NonNullType' ],

  # Type System Definitions
  [ SCHEMA_DEFINITION => 'SchemaDefinition' ],
  [ OPERATION_TYPE_DEFINITION => 'OperationTypeDefinition' ],

  # Type Definitions
  [ SCALAR_TYPE_DEFINITION => 'ScalarTypeDefinition' ],
  [ OBJECT_TYPE_DEFINITION => 'ObjectTypeDefinition' ],
  [ FIELD_DEFINITION => 'FieldDefinition' ],
  [ INPUT_VALUE_DEFINITION => 'InputValueDefinition' ],
  [ INTERFACE_TYPE_DEFINITION => 'InterfaceTypeDefinition' ],
  [ UNION_TYPE_DEFINITION => 'UnionTypeDefinition' ],
  [ ENUM_TYPE_DEFINITION => 'EnumTypeDefinition' ],
  [ ENUM_VALUE_DEFINITION => 'EnumValueDefinition' ],
  [ INPUT_OBJECT_TYPE_DEFINITION => 'InputObjectTypeDefinition' ],

  # Directive Definitions
  [ DIRECTIVE_DEFINITION => 'DirectiveDefinition' ],

  # Type System Extensions
  [ SCHEMA_EXTENSION => 'SchemaExtension' ],

  # Type Extensions
  [ SCALAR_TYPE_EXTENSION => 'ScalarTypeExtension' ],
  [ OBJECT_TYPE_EXTENSION => 'ObjectTypeExtension' ],
  [ INTERFACE_TYPE_EXTENSION => 'InterfaceTypeExtension' ],
  [ UNION_TYPE_EXTENSION => 'UnionTypeExtension' ],
  [ ENUM_TYPE_EXTENSION => 'EnumTypeExtension' ],
  [ INPUT_OBJECT_TYPE_EXTENSION => 'InputObjectTypeExtension' ],
);

my $Kind = type 'Kind', as Enum[ map { $_->[1] } @KINDS ];

my %KindMap = map {
    my ($key, $value) = @$_;
    $key => type "Kind_$key", as Enum[ $value ]
} @KINDS;

sub Kind(;$) {
    unless (@_) {
        return $Kind;
    }

    my ($kind) = @{ $_[0] };
    $KindMap{$kind} or croak "Cannot find kind: $kind";
}

1;
