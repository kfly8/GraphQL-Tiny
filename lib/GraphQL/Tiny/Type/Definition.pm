package GraphQL::Tiny::Type::Definition;
use strict;
use warnings;
use feature qw(state);
use GraphQL::Tiny::Inner::TypeUtils qw(type as where);
use GraphQL::Tiny::Inner::TypeLibrary qw(
    Any
    ArrayRef
    CodeRef
    Dict
    Map
    Maybe
    Null
    Optional
    ReadonlyArray
    Str
    Undef
    Unknown
);

use Carp qw(croak);

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);
use GraphQL::Tiny::Utils::Error qw(build_error);
use GraphQL::Tiny::Utils::Path qw(Path);
use GraphQL::Tiny::Utils::IdentityFunc qw(identity_func);
use GraphQL::Tiny::Utils::ToObjMap qw(to_obj_map);

use GraphQL::Tiny::Error::GraphQLError qw(build_graphql_error);

our @EXPORT_OK = qw(
    is_type              assert_type

    is_scalar_type       assert_scalar_type
    is_object_type       assert_object_type
    is_interface_type    assert_interface_type
    is_union_type        assert_union_type
    is_enum_type         assert_enum_type
    is_input_object_type assert_input_object_type
    is_list_type         assert_list_type
    is_non_null_type     assert_non_null_type

    is_input_type        assert_input_type
    is_output_type       assert_output_type
    is_leaf_type         assert_leaf_type
    is_composite_type    assert_composite_type
    is_abstract_type     assert_abstract_type
    is_wrapping_type     assert_wrapping_type
    is_nullable_type     assert_nullable_type      get_nullable_type
    is_named_type        assert_named_type         get_named_type

    resolve_readonly_array_thunk
    resolve_obj_map_thunk

    define_arguments
    args_to_args_config
    is_required_argument
    is_required_input_field

    build_graphql_list
    build_graphql_non_null
    build_graphql_scalar_type
    build_graphql_object_type
    build_graphql_interface_type
    build_graphql_union_type
    build_graphql_enum_type
    build_graphql_input_object_type

    get_fields_object_type
    get_fields_interface_type
    get_fields_input_object_type

    get_values_enum_type
    get_value_enum_type
);

use Type::Library
    -base,
    -declare => qw(
        GraphQLType
        GraphQLArgument

        GraphQLScalarType
        GraphQLObjectType
        GraphQLInterfaceType
        GraphQLUnionType
        GraphQLEnumType
        GraphQLInputObjectType
        GraphQLList
        GraphQLNonNull

        GraphQLNullableInputType GraphQLNamedInputType GraphQLInputType
        GraphQLNullableOutputType GraphQLNamedOutputType GraphQLOutputType

        GraphQLLeafType
        GraphQLCompositeType
        GraphQLAbstractType
        GraphQLWrappingType
        GraphQLNullableType
        GraphQLNamedType

        ThunkReadonlyArray
        ThunkObjMap

        GraphQLScalarTypeExtensions
        GraphQLObjectTypeExtensions

        GraphQLScalarSerializer GraphQLScalarValueParser GraphQLScalarLiteralParser
        GraphQLScalarTypeConfig GraphQLScalarTypeNormalizedConfig

        GraphQLObjectTypeConfig
        GraphQLFieldArgumentMap
        GraphQLInterfaceTypeConfig

        GraphQLTypeResolver
        GraphQLIsTypeOfFn
        GraphQLFieldResolver
        GraphQLResolveInfo

        GraphQLFieldExtensions
        GraphQLFieldConfig
        GraphQLFieldConfigArgumentMap
        GraphQLArgumentExtensions
        GraphQLArgumentConfig
        GraphQLFieldConfigMap
        GraphQLField
        GraphQLArgument
        GraphQLFieldMap

        GraphQLInterfaceTypeExtensions
        GraphQLInterfaceType
        GraphQLInterfaceTypeConfig
        GraphQLInterfaceTypeNormalizedConfig

        GraphQLUnionTypeExtensions
        GraphQLUnionType
        GraphQLUnionTypeConfig
        GraphQLUnionTypeNormalizedConfig

        GraphQLEnumTypeExtensions
        GraphQLEnumType
        GraphQLEnumTypeConfig
        GraphQLEnumTypeNormalizedConfig
        GraphQLEnumValueExtensions
        GraphQLEnumValueConfig
        GraphQLEnumValueConfigMap
        GraphQLEnumValue

        GraphQLInputObjectTypeExtensions
        GraphQLInputObjectType
        GraphQLInputObjectTypeConfig
        GraphQLInputObjectTypeNormalizedConfig

        GraphQLInputFieldExtensions
        GraphQLInputFieldConfigMap
        GraphQLInputFieldConfig
        GraphQLInputField
        GraphQLInputFieldMap
    );

# TODO(port): inspect
sub inspect;

use GraphQL::Tiny::Language::Ast qw(
    EnumTypeDefinitionNode
    EnumTypeExtensionNode
    EnumValueDefinitionNode
    FieldDefinitionNode
    FieldNode
    FragmentDefinitionNode
    InputObjectTypeDefinitionNode
    InputObjectTypeExtensionNode
    InputValueDefinitionNode
    InterfaceTypeDefinitionNode
    InterfaceTypeExtensionNode
    ObjectTypeDefinitionNode
    ObjectTypeExtensionNode
    OperationDefinitionNode
    ScalarTypeDefinitionNode
    ScalarTypeExtensionNode
    UnionTypeDefinitionNode
    UnionTypeExtensionNode
    ValueNode
);

use GraphQL::Tiny::Language::Kinds qw(Kind);

# TODO(port): language/printer
sub print;

# TODO(port): language/value_from_ast_untyped
sub value_from_ast_untyped { ... };

use GraphQL::Tiny::Type::AssertName qw(assert_enum_value_name assert_name);

# TODO(port): type/schema
#use GraphQL::Tiny::Type::Schema qw(GraphQLSchema);
sub GraphQLSchema { Str };

# Predicates & Assertions


# These are all of the possible kinds of types.
type 'GraphQLType', as GraphQLNamedType | GraphQLWrappingType;

sub is_type {
    my ($type) = @_;
    return (
        is_scalar_type($type)
        || is_object_type($type)
        || is_interface_type($type)
        || is_union_type($type)
        || is_enum_type($type)
        || is_input_object_type($type)
        || is_list_type($type)
        || is_non_null_type($type)
    );
}

sub assert_type {
    my ($type) = @_;
    if (!is_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL type.');
    }
    return $type;
}

# There are predicates for each kind of GraphQL type.
sub is_scalar_type {
    my ($type) = @_;
    return GraphQLScalarType->check($type);
}

sub assert_scalar_type {
    my ($type) = @_;
    if (!is_scalar_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL Scalar type.');
    }
    return $type;
}

sub is_object_type {
    my ($type) = @_;
    return GraphQLObjectType->check($type);
}

sub assert_object_type {
    my ($type) = @_;
    if (!is_object_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL Object type.');
    }
    return $type;
}

sub is_interface_type {
    my ($type) = @_;
    return GraphQLInterfaceType->check($type);
}

sub assert_interface_type {
    my ($type) = @_;
    if (!is_interface_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL Interface type.');
    }
    return $type;
}

sub is_union_type {
    my ($type) = @_;
    return GraphQLUnionType->check($type);
}

sub assert_union_type {
    my ($type) = @_;
    if (!is_union_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL Union type.');
    }
    return $type;
}

sub is_enum_type {
    my ($type) = @_;
    return GraphQLEnumType->check($type);
}

sub assert_enum_type {
    my ($type) = @_;
    if (!is_enum_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL Enum type.');
    }
    return $type;
}

sub is_input_object_type {
    my ($type) = @_;
    return GraphQLInputObjectType->check($type);
}

sub assert_input_object_type {
    my ($type) = @_;
    if (!is_input_object_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL Input Object type.');
    }
    return $type;
}

sub is_list_type {
    my ($type) = @_;
    return GraphQLList->check($type);
}

sub assert_list_type {
    my ($type) = @_;
    if (!is_list_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL List type.');
    }
    return $type;
}

sub is_non_null_type {
    my ($type) = @_;
    return GraphQLNonNull->check($type);
}

sub assert_non_null_type {
    my ($type) = @_;
    if (!is_non_null_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL Non-Null type.');
    }
    return $type;
}

# These types may be used as input types for arguments and directives.
type 'GraphQLNullableInputType', where {
    state $Type = GraphQLNamedInputType | GraphQLList[GraphQLInputType];
    $Type->check($_);
};

type 'GraphQLInputType', where {
    state $Type = GraphQLNullableInputType | GraphQLNonNull[GraphQLNullableInputType];
    $Type->check($_);
};


sub is_input_type {
    my ($type) = @_;
    return (
        is_scalar_type($type)
        || is_enum_type($type)
        || is_input_object_type($type)
        || (is_wrapping_type($type) && is_input_type($type->of_type))
    );
}

sub assert_input_type {
    my ($type) = @_;
    if (!is_input_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL input type.');
    }
    return $type;
}

# These types may be used as output types as the result of fields.
type 'GraphQLNullableOutputType', where {
    state $Type = GraphQLNamedOutputType | GraphQLList[GraphQLOutputType];
    $Type->check($_);
};

type 'GraphQLOutputType', where {
    state $Type = GraphQLNullableOutputType | GraphQLNonNull[GraphQLNullableOutputType];
    $Type->check($_);
};

sub is_output_type {
    my ($type) = @_;
    return (
        is_scalar_type($type)
        || is_object_type($type)
        || is_interface_type($type)
        || is_union_type($type)
        || is_enum_type($type)
        || (is_wrapping_type($type) && is_output_type($type->of_type))
    );
}

sub assert_output_type {
    my ($type) = @_;
    if (!is_output_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL output type.');
    }
    return $type;
}

# These types may describe types which may be leaf values.
type 'GraphQLLeafType', as GraphQLScalarType | GraphQLEnumType;

sub is_leaf_type {
    my ($type) = @_;
    return is_scalar_type($type) || is_enum_type($type);
}

sub assert_leaf_type {
    my ($type) = @_;
    if (!is_leaf_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL leaf type.');
    }
    return $type;
}

# These types may describe the parent context of a selection set.
type 'GraphQLCompositeType', as
    GraphQLObjectType
  | GraphQLInterfaceType
  | GraphQLUnionType;

sub is_composite_type {
    my ($type) = @_;
    return is_object_type($type) || is_interface_type($type) || is_union_type($type);
}

sub assert_composite_type {
    my ($type) = @_;
    if (!is_composite_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL composite type.');
    }
    return $type;
}

# These types may describe the parent context of a selection set.
type 'GraphQLAbstractType', as GraphQLInterfaceType | GraphQLUnionType;

sub is_abstract_type {
    my ($type) = @_;
    return is_interface_type($type) || is_union_type($type);
}

sub assert_abstract_type {
    my ($type) = @_;
    if (!is_abstract_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL abstract type.');
    }
    return $type;
}



# List Type Wrapper
#
# A list is a wrapping type which points to another type.
# Lists are often created within the context of defining the fields of
# an object type.
#
# Example:
#
# ```ts
# const PersonType = new GraphQLObjectType({
#   name: 'Person',
#   fields: () => ({
#     parents: { type: new GraphQLList(PersonType) },
#     children: { type: new GraphQLList(PersonType) },
#   })
# })
# ```
type 'GraphQLList', as Dict,
    name_generator => sub {
        my ($type_name, $param) = @_;
        sprintf '%s[%s]', $type_name, $param;
    },
    constraint_generator => sub {
        my ($param) = @_;
        if (ASSERT) {
            GraphQLType->is_a_type_of($param) or croak 'Invalid type' . "$param";
        }
        my $Type = Dict[ofType => ArrayRef[$param]];
        return sub { $Type->check(@_) }
    };

sub build_graphql_list {
    my ($of_type) = @_;
    return {
        ofType => $of_type,
    };
}

# Non-Null Type Wrapper
#
# A non-null is a wrapping type which points to another type.
# Non-null types enforce that their values are never null and can ensure
# an error is raised if this ever occurs during a request. It is useful for
# fields which you can make a strong guarantee on non-nullability, for example
# usually the id field of a database row will never be null.
#
# Example:
#
# ```ts
# const RowType = new GraphQLObjectType({
#   name: 'Row',
#   fields: () => ({
#     id: { type: new GraphQLNonNull(GraphQLString) },
#   })
# })
# ```
# Note: the enforcement of non-nullability occurs within the executor.
type 'GraphQLNonNull', as Dict,
    name_generator => sub {
        my ($type_name, $param) = @_;
        sprintf '%s[%s]', $type_name, $param;
    },
    constraint_generator => sub {
        my ($param) = @_;
        if (ASSERT) {
            GraphQLNullableType->is_a_type_of($param) or croak 'Invalid type' . "$param";
        }
        my $Type = Dict[ofType => $param];
        return sub { $Type->check(@_) }
    };

sub build_graphql_non_null {
    my ($of_type) = @_;
    return {
        ofType => $of_type,
    };
}


# These types wrap and modify other types

type 'GraphQLWrappingType', where {
    state $Type = GraphQLList[GraphQLType] | GraphQLNonNull[GraphQLNullableType];
    $Type->check($_);
};

sub is_wrapping_type {
    my ($type) = @_;
    return is_list_type($type) || is_non_null_type($type);
}

sub assert_wrapping_type {
    my ($type) = @_;
    if (!is_wrapping_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL wrapping type.');
    }
    return $type;
}

# These types can all accept null as a value.
type 'GraphQLNullableType', where {
    state $Type = GraphQLNamedType | GraphQLList[GraphQLType];
    $Type->check($_);
};

sub is_nullable_type {
    my ($type) = @_;
    return is_type($type) && !is_non_null_type($type);
}

sub assert_nullable_type {
    my ($type) = @_;
    if (!is_nullable_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL nullable type.');
    }
    return $type;
}

sub get_nullable_type {
    my ($type) = @_;
    if ($type) {
        return is_non_null_type($type) ? $type->{ofType} : $type;
    }
}

# These named types do not include modifiers like List or NonNull.
type 'GraphQLNamedType', as GraphQLNamedInputType | GraphQLNamedOutputType;

type 'GraphQLNamedInputType', as
    GraphQLScalarType
  | GraphQLEnumType
  | GraphQLInputObjectType;

type 'GraphQLNamedOutputType', as
    GraphQLScalarType
  | GraphQLObjectType
  | GraphQLInterfaceType
  | GraphQLUnionType
  | GraphQLEnumType;

sub is_named_type {
    my ($type) = @_;
    return (
        is_scalar_type($type) ||
        is_object_type($type) ||
        is_interface_type($type) ||
        is_union_type($type) ||
        is_enum_type($type) ||
        is_input_object_type($type)
    )
}

sub assert_named_type {
    my ($type) = @_;
    if (!is_named_type($type)) {
        croak build_error('Expected ' . inspect($type) . ' to be a GraphQL named type.');
    }
    return $type;
}

sub get_named_type {
    my ($type) = @_;
    if ($type) {
        my $unwrapped_type = $type;
        while (is_wrapping_type($unwrapped_type)) {
            $unwrapped_type = $unwrapped_type->{ofType};
        }
        return $unwrapped_type;
    }
}


# Used while defining GraphQL types to allow for circular references in
# otherwise immutable type definitions.
type 'ThunkReadonlyArray', as CodeRef | ReadonlyArray,
    name_generator => sub {
        my ($type_name, $param) = @_;
        sprintf '%s[%s]', $type_name, $param;
    },
    constraint_generator => sub {
        my ($param) = @_;
        # TODO implement this
        my $Type = Types::Standard::ArrayRef->of($param);
        return sub { $Type->check(@_) }
    };

type 'ThunkObjMap', as CodeRef | Map,
    name_generator => sub {
        my ($type_name, $param) = @_;
        sprintf '%s[%s]', $type_name, $param;
    },
    constraint_generator => sub {
        my ($param) = @_;
        # TODO implement this
        my $Type = Types::Standard::ArrayRef->of($param);
        return sub { $Type->check(@_) }
    };

sub resolve_readonly_array_thunk {
    my ($thunk) = @_;
    if (ASSERT) {
        ThunkReadonlyArray->check($thunk);
    }
    return ref $thunk eq 'CODE' ? $thunk->() : $thunk;
}

sub resolve_obj_map_thunk {
    my ($thunk) = @_;
    if (ASSERT) {
        ThunkObjMap->check($thunk);
    }
    return ref $thunk eq 'CODE' ? $thunk->() : $thunk;
}


# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLScalarTypeExtensions', as Map[Str, Unknown];

# Scalar Type Definition
#
# The leaf values of any request and input values to arguments are
# Scalars (or Enums) and are defined with a name and a series of functions
# used to parse input from ast or variables and to ensure validity.
#
# If a type's serialize sub returns `null` or does not return a value
# (i.e. it returns `undefined`) then an error will be raised and a `null`
# value will be returned in the response. It is always better to validate
#
# Example:
#
# ```ts
# const OddType = new GraphQLScalarType({
#   name: 'Odd',
#   serialize(value) {
#     if (!Number.isFinite(value)) {
#       throw new Error(
#         `Scalar "Odd" cannot represent "${value}" since it is not a finite number.`,
#       );
#     }
#
#     if (value % 2 === 0) {
#       throw new Error(`Scalar "Odd" cannot represent "${value}" since it is even.`);
#     }
#     return value;
#   }
# });
# ```
type 'GraphQLScalarType',
    as Dict[
        name => Str,
        description => Maybe[Str],
        specifiedByURL => Maybe[Str],
        serialize => GraphQLScalarSerializer,
        parseValue => GraphQLScalarValueParser,
        parseLiteral => GraphQLScalarLiteralParser,
        extensions => GraphQLScalarTypeExtensions,
        astNode => Maybe[ScalarTypeDefinitionNode],
        extensionASTNodes => ReadonlyArray[ScalarTypeExtensionNode],
    ];

sub build_graphql_scalar_type {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLScalarTypeConfig->assert_valid($config);
    }

    my $parse_value = $config->{parseValue} // \&identity_func;

    my $type = {};
    $type->{name} = assert_name($config->{name});
    $type->{description} = $config->{description};
    $type->{specifiedByURL} = $config->{specifiedByURL};
    $type->{serialize} = $config->{serialize} // \&identity_func;
    $type->{parseValue} = $parse_value;
    $type->{parseLiteral} = $config->{parseLiteral} // sub {
        my ($node, $variables) = @_;
        return $parse_value->(value_from_ast_untyped($node, $variables));
    };
    $type->{extensions} = to_obj_map($config->{extensions});
    $type->{astNode} = $config->{astNode};
    $type->{extensionASTNodes} = $config->{extensionASTNodes} // [];

    if ($config->{parseLiteral}) {
        unless ( ref $config->{parseValue} eq 'CODE' && ref $config->{parseLiteral} eq 'CODE') {
            croak build_error(sprintf('%s must provide both "parseValue" and "parseLiteral" functions.', $type->{name}));
        }
    }

    return $type;
}

# TODO(port) toConfig, toString, toJSON

# TODO(port): TExternal, TInternal
# export type GraphQLScalarSerializer<TExternal> = (
#   outputValue: unknown,
# ) => TExternal;
type 'GraphQLScalarSerializer', as CodeRef;

# export type GraphQLScalarValueParser<TInternal> = (
#   inputValue: unknown,
# ) => TInternal;
type 'GraphQLScalarValueParser', as CodeRef;

# export type GraphQLScalarLiteralParser<TInternal> = (
#   valueNode: ValueNode,
#   variables?: Maybe<ObjMap<unknown>>,
# ) => TInternal;
type 'GraphQLScalarLiteralParser', as CodeRef;

type 'GraphQLScalarTypeConfig',
    as Dict[
        name => Str,
        description => Optional[ Maybe[Str] ],
        specifiedByURL => Optional[ Maybe[Str] ],
        # Serializes an internal value to include in a response.
        serialize => Optional[ Maybe[GraphQLScalarSerializer] ],
        # Parses an externally provided value to use as an input.
        parseValue => Optional[ Maybe[GraphQLScalarValueParser] ],
        # Parses an externally provided literal value to use as an input.
        parseLiteral => Optional[ Maybe[GraphQLScalarLiteralParser] ],
        extensions => Optional[ Maybe[GraphQLScalarTypeExtensions] ],
        astNode => Optional[ Maybe[ScalarTypeDefinitionNode] ],
        extensionASTNodes => Optional[ Maybe[ReadonlyArray[ScalarTypeExtensionNode]] ],
    ];

# TODO(port) extends => 'GraphQLScalarTypeConfig',
type 'GraphQLScalarTypeNormalizedConfig',
    as Dict[
        serialize => GraphQLScalarSerializer,
        parseValue => GraphQLScalarValueParser,
        parseLiteral => GraphQLScalarLiteralParser,
        extensions => GraphQLScalarTypeExtensions, # TODO Readonly
        extensionASTNodes => ReadonlyArray[ScalarTypeExtensionNode],
    ];


# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
#
# We've provided these template arguments because this is an open type and
# you may find them useful.

# TODO(port): TSource, TContext
type 'GraphQLObjectTypeExtensions', as Map[Str, Unknown];

# Object Type Definition
#
# Almost all of the GraphQL types you define will be object types. Object types
# have a name, but most importantly describe their fields.
#
# Example:
#
# ```ts
# const AddressType = new GraphQLObjectType({
#   name: 'Address',
#   fields: {
#     street: { type: GraphQLString },
#     number: { type: GraphQLInt },
#     formatted: {
#       type: GraphQLString,
#       resolve(obj) {
#         return obj.number + ' ' + obj.street
#       }
#     }
#   }
# });
# ```
#
# When two types need to refer to each other, or a type needs to refer to
# itself in a field, you can use a sub expression (aka a closure or a
# thunk) to supply the fields lazily.
#
# Example:
#
# ```ts
# const PersonType = new GraphQLObjectType({
#   name: 'Person',
#   fields: () => ({
#     name: { type: GraphQLString },
#     bestFriend: { type: PersonType },
#   })
# });
# ```
type 'GraphQLObjectType',
    as Dict[
        name => Str,
        description => Maybe[Str],
        isTypeOf => Maybe[GraphQLIsTypeOfFn],
        extensions => GraphQLObjectTypeExtensions,
        astNode => Maybe[ObjectTypeDefinitionNode],
        extensionASTNodes => ReadonlyArray[ObjectTypeExtensionNode],
        _fields => ThunkObjMap[GraphQLField],
        _interfaces => ThunkReadonlyArray[GraphQLInterfaceType],
    ];

sub build_graphql_object_type {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLObjectTypeConfig->assert_valid($config);
    }

    my $type = {};
    $type->{name} = assert_name($config->{name});
    $type->{description} = $config->{description};
    $type->{isTypeOf} = $config->{isTypeOf};
    $type->{extensions} = to_obj_map($config->{extensions});
    $type->{astNode} = $config->{astNode};
    $type->{extensionASTNodes} = $config->{extensionASTNodes} // [];

    $type->{_fields} = sub { define_field_map($config) };
    $type->{_interfaces} = sub { define_interfaces($config) };
}

sub get_fields_object_type {
    my ($type) = @_;

    if (ASSERT) {
        GraphQLObjectType->assert_valid($type);
    }

    if (ref $type->{_fields} eq 'CODE') {
        $type->{_fields} = $type->{_fields}->();
    }
    return $type->{_fields};
}

sub get_interfaces_object_type {
    my ($type) = @_;

    if (ASSERT) {
        GraphQLObjectType->assert_valid($type);
    }

    if (ref $type->{_interfaces} eq 'CODE') {
        $type->{_interfaces} = $type->{_interfaces}->();
    }
    return $type->{_interfaces};
}

# TODO(port): toConfig, toString, toJSON

sub define_interfaces {
    my ($config) = @_;
    if (ASSERT) {
        my $Type = GraphQLObjectTypeConfig | GraphQLInterfaceTypeConfig;
        $Type->assert_valid($config);
    }

    my $interfaces = resolve_readonly_array_thunk($config->{interfaces} // []);
    if (ASSERT) {
        ReadonlyArray[GraphQLInterfaceType]->assert_valid($interfaces);
    }
    return $interfaces;
}

sub define_field_map {
    my ($config) = @_;

    if (ASSERT) {
        my $Type = GraphQLObjectTypeConfig | GraphQLInterfaceTypeConfig;
        $Type->assert_valid($config);
    }

    my $field_map = resolve_obj_map_thunk($config->{fields});

    my $map = map_value($field_map, sub {
        my ($field_config, $field_name) = @_;

        my $args_config = $field_config->{args} // {};

        return {
            name => assert_name($field_name),
            description => $field_config->{description},
            type => $field_config->{type},
            args => define_arguments($args_config),
            resolve => $field_config->{resolve},
            subscribe => $field_config->{subscribe},
            deprecationReason => $field_config->{deprecationReason},
            extensions => to_obj_map($field_config->{extensions}),
            astNode => $field_config->{astNode},
        }
    });

    if (ASSERT) {
        GraphQLFieldMap->assert_valid($map);
    }

    return $map;
}

sub define_arguments {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLFieldConfigArgumentMap->assert_valid($config);
    }

    my $arguments = [
        map {
            my $arg_name = $_;
            my $arg_config = $config->{$arg_name};

            {
                name => assert_name($arg_name),
                description => $arg_config->{description},
                type => $arg_config->{type},
                defaultValue => $arg_config->{defaultValue},
                deprecationReason => $arg_config->{deprecationReason},
                extensions => to_obj_map($arg_config->{extensions}),
                astNode => $arg_config->{astNode},
            }
        } keys %$config
    ];

    if (ASSERT) {
        ReadonlyArray[GraphQLArgument]->assert_valid($arguments);
    }
    return $arguments;
}

sub fields_to_fields_config {
    my ($fields) = @_;
    if (ASSERT) {
        GraphQLFieldMap->assert_valid($fields);
    }

    my $map = map_value($fields, sub {
        my ($field) = @_;
        return {
            description => $field->{description},
            type => $field->{type},
            args => args_to_args_config($field->{args}),
            resolve => $field->{resolve},
            subscribe => $field->{subscribe},
            deprecationReason => $field->{deprecationReason},
            extensions => $field->{extensions},
            astNode => $field->{astNode},
        };
    });

    if (ASSERT) {
        GraphQLFieldConfigMap->assert_valid($map);
    }
    return $map;
}


# @internal
sub args_to_args_config {
    my ($args) = @_;
    if (ASSERT) {
        ReadonlyArray[GraphQLArgument]->assert_valid($args);
    }

    my $map = key_val_map(
        $args,
        sub {
            my ($arg) = @_;
            $arg->{name}
        },
        sub {
            my ($arg) = @_;
            {
                description => $arg->{description},
                type => $arg->{type},
                defaultValue => $arg->{defaultValue},
                deprecationReason => $arg->{deprecationReason},
                extensions => $arg->{extensions},
                astNode => $arg->{astNode},
            }
        },
    );

    if (ASSERT) {
        GraphQLFieldConfigArgumentMap->assert_valid($map);
    }
    return $map;
}

type 'GraphQLObjectTypeConfig',
    as Dict[
        name => Str,
        description => Optional[Maybe[Str]],
        interfaces => Optional[ThunkReadonlyArray[GraphQLInterfaceType] | Undef],
        fields => ThunkObjMap[GraphQLFieldConfig],
        isTypeOf => Optional[Maybe[GraphQLIsTypeOfFn]],
        extensions => Optional[Maybe[GraphQLObjectTypeExtensions]], # TODO: Readonly
        astNode => Optional[Maybe[ObjectTypeDefinitionNode]],
        extensionASTNodes => Optional[Maybe[ReadonlyArray[ObjectTypeExtensionNode]]],
    ];

type 'GraphQLObjectTypeNormalizedConfig',
    as Dict[
        extends => GraphQLObjectTypeConfig,
        interfaces => ReadonlyArray[GraphQLInterfaceType],
        fields => GraphQLFieldConfigMap,
        extensions => GraphQLObjectTypeExtensions, # TODO Readonly
        extensionASTNodes => ReadonlyArray[ObjectTypeExtensionNode],
    ];


#type GraphQLTypeResolver<TSource, TContext> = (
#  value: TSource,
#  context: TContext,
#  info: GraphQLResolveInfo,
#  abstractType: GraphQLAbstractType,
#) => PromiseOrValue<string | undefined>;
type 'GraphQLTypeResolver', as CodeRef;

#type GraphQLIsTypeOfFn<TSource, TContext> = (
#  source: TSource,
#  context: TContext,
#  info: GraphQLResolveInfo,
#) => PromiseOrValue<boolean>;
type 'GraphQLIsTypeOfFn', as CodeRef;


# (
#   source: TSource,
#   args: TArgs,
#   context: TContext,
#   info: GraphQLResolveInfo,
# ) => TResult;
type 'GraphQLFieldResolver', as CodeRef;

type 'GraphQLResolveInfo',
    as Dict[
        fieldName => Str,
        fieldNodes => ReadonlyArray[FieldNode],
        returnType => GraphQLOutputType,
        parentType => GraphQLObjectType,
        path => Path,
        schema => GraphQLSchema,
        fragments => Map[Str, FragmentDefinitionNode],
        rootValue => Unknown,
        operation => OperationDefinitionNode,
        variableValues => Map[Str, Unknown],
    ];

# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
#
# We've provided these template arguments because this is an open type and
# you may find them useful.
type 'GraphQLFieldExtensions',
    as Dict[Str, Unknown];

type 'GraphQLFieldConfig',
    as Dict[
        description => Optional[Maybe[Str]],
        type => GraphQLOutputType,
        args => Optional[ GraphQLFieldConfigArgumentMap | Undef],
        resolve => Optional[ GraphQLFieldResolver | Undef],
        subscribe => Optional[ GraphQLFieldResolver | Undef],
        deprecationReason => Optional[Str | Undef | Null ],
        extensions => Optional[GraphQLFieldExtensions | Undef | Null ],
        astNode => Optional[ FieldDefinitionNode | Undef | Null ],
    ];

type 'GraphQLFieldConfigArgumentMap',
    as Map[Str, GraphQLArgumentConfig];


# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLArgumentExtensions',
    as Map[Str, Unknown];

type 'GraphQLArgumentConfig',
    as Dict[
        description => Optional[Str | Undef | Null ],
        type => GraphQLInputType,
        defaultValue => Optional[Unknown],
        deprecationReason => Optional[Str | Undef | Null ],
        extensions => Optional[GraphQLArgumentExtensions | Undef | Null ],
        astNode => Optional[ InputValueDefinitionNode | Undef | Null ],
    ];

type 'GraphQLFieldConfigMap',
    as Map[Str, GraphQLFieldConfig];

type 'GraphQLField',
    as Dict[
        name => Str,
        description => Optional[Str | Undef | Null ],
        type => GraphQLOutputType,
        args => ReadonlyArray[GraphQLArgument],
        resolve => Optional[ GraphQLFieldResolver | Undef],
        subscribe => Optional[ GraphQLFieldResolver | Undef],
        deprecationReason => Optional[Str | Undef | Null ],
        extensions => Optional[GraphQLFieldExtensions | Undef | Null ],
        astNode => Optional[ FieldDefinitionNode | Undef | Null ],
    ];

type 'GraphQLArgument',
    as Dict[
        name => Str,
        description => Optional[Str | Undef | Null ],
        type => GraphQLInputType,
        defaultValue => Optional[Unknown],
        deprecationReason => Optional[Str | Undef | Null ],
        extensions => Optional[GraphQLArgumentExtensions | Undef | Null ],
        astNode => Optional[ InputValueDefinitionNode | Undef | Null ],
    ];

sub is_required_argument {
    my ($arg) = @_;
    if (ASSERT) {
        GraphQLArgument->assert_valid($arg);
    }
    return is_non_null_type($arg->{type}) && !defined $arg->{defaultValue};
}

type 'GraphQLFieldMap',
    as Map[Str, GraphQLField];


# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLInterfaceTypeExtensions',
    as Map[Str, Unknown];

# Interface Type Definition
#
# When a field can return one of a heterogeneous set of types, a Interface type
# is used to describe what types are possible, what fields are in common across
# all types, as well as a sub to determine which type is actually used
# when the field is resolved.
#
# Example:
#
# ```ts
# const EntityType = new GraphQLInterfaceType({
#   name: 'Entity',
#   fields: {
#     name: { type: GraphQLString }
#   }
# });
# ```
type 'GraphQLInterfaceType',
    as Dict[
        name => Str,
        description => Str | Undef | Null,
        resolveType => GraphQLTypeResolver | Undef | Null,
        extensions => GraphQLInterfaceTypeExtensions, # Readonly
        astNode => InterfaceTypeDefinitionNode | Undef | Null,
        extensionASTNodes => ReadonlyArray[InterfaceTypeExtensionNode],

        _fields => ThunkObjMap[GraphQLField],
        _interfaces => ThunkReadonlyArray[GraphQLInterfaceType],
    ];

sub build_graphql_iterface_type {
    my ($config) = @_;
    if (ASSERT) {
        GraphQLInterfaceType->assert_valid($config);
    }

    my $type = {};
    $type->{name} = assert_name($config->{name});
    $type->{description} = $config->{description};
    $type->{resolveType} = $config->{resolveType};
    $type->{extensions} = to_obj_map($config->{extensions});
    $type->{astNode} = $config->{astNode};
    $type->{extensionASTNodes} = $config->{extensionASTNodes} // [];

    $type->{_fields} = define_field_map($config);
    $type->{_interfaces} = define_interfaces($config);

    if (ASSERT) {
        GraphQLInterfaceType->assert_valid($type);
    }
    return $type;
  }

sub get_fields_interface_type {
    my ($type) = @_;

    if (ASSERT) {
        GraphQLInterfaceType->assert_valid($type);
    }

    if (ref $type->{_fields} eq 'CODE') {
        $type->{_fields} = $type->{_fields}->();
    }

    if (ASSERT) {
        GraphQLFieldMap->assert_valid($type->{_fields});
    }

    return $type->{_fields};
}

sub get_interfaces_interface_type {
    my ($type) = @_;

    if (ASSERT) {
        GraphQLInterfaceType->assert_valid($type);
    }

    if (ref $type->{_interfaces} eq 'CODE') {
        $type->{_interfaces} = $type->{_interfaces}();
    }

    if (ASSERT) {
        ReadonlyArray[GraphQLInterfaceType]->assert_valid($type->{_interfaces});
    }

    return $type->{_interfaces};
}

# TODO(port): toConfig, toString, toJSON

type 'GraphQLInterfaceTypeConfig',
    as Dict[
        name => Str,
        description => Optional[ Str | Undef | Null ],
        interfaces => Optional[ ReadonlyArray[GraphQLInterfaceType] ],
        fields => Optional[ ThunkReadonlyArray[ GraphQLFieldConfigMap ] | Undef ],

        # Optionally provide a custom type resolver function. If one is not provided,
        # the default implementation will call `isTypeOf` on each implementing
        # Object type.
        resolveType => Optional[ GraphQLTypeResolver | Undef | Null ],
        extensions => Optional[ GraphQLInterfaceTypeExtensions ], # Readonly
        astNode => Optional[ InterfaceTypeDefinitionNode | Undef | Null ],
        extensionASTNodes => Optional[ ReadonlyArray[InterfaceTypeExtensionNode] | Undef | Null ],
    ];

type 'GraphQLInterfaceTypeNormalizedConfig',
    as Dict[
        extends => GraphQLInterfaceTypeConfig,
        interfaces => ReadonlyArray[GraphQLInterfaceType],
        fields => GraphQLFieldConfigMap,
        extensions => GraphQLInterfaceTypeExtensions, # Readonly
        extensionASTNodes => ReadonlyArray[InterfaceTypeExtensionNode],
    ];

# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLUnionTypeExtensions',
    as Map[Str, Unknown];

# Union Type Definition
#
# When a field can return one of a heterogeneous set of types, a Union type
# is used to describe what types are possible as well as providing a function
# to determine which type is actually used when the field is resolved.
#
# Example:
#
# ```ts
# const PetType = new GraphQLUnionType({
#   name: 'Pet',
#   types: [ DogType, CatType ],
#   resolveType(value) {
#     if (value instanceof Dog) {
#       return DogType;
#     }
#     if (value instanceof Cat) {
#       return CatType;
#     }
#   }
# });
# ```
type 'GraphQLUnionType',
    as Dict[
        name => Str,
        description => Str | Undef | Null,
        resolveType => GraphQLTypeResolver | Undef | Null,
        extensions => GraphQLUnionTypeExtensions, # Readonly
        astNode => UnionTypeDefinitionNode | Undef | Null,
        extensionASTNodes => ReadonlyArray[UnionTypeExtensionNode],

        _types => ThunkReadonlyArray[GraphQLObjectType],
    ];

sub build_graphql_union_type {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLUnionTypeConfig->assert_valid($config);
    }

    my $type = {};
    $type->{name} = assert_name($config->{name});
    $type->{description} = $config->{description};
    $type->{resolveType} = $config->{resolveType};
    $type->{extensions} = to_obj_map($config->{extensions});
    $type->{astNode} = $config->{astNode};
    $type->{extensionASTNodes} = $config->{extensionASTNodes} // [];

    $type->{_types} = define_types($config);

    if (ASSERT) {
        GraphQLUnionType->assert_valid($type);
    }

    return $type;
}

sub get_types_union_type {
    my ($type) = @_;

    if (ASSERT) {
        GraphQLUnionType->assert_valid($type);
    }

    if (ref $type->{_types} eq 'CODE') {
        $type->{_types} = $type->{_types}->();
    }

    if (ASSERT) {
        ReadonlyArray[GraphQLObjectType]->assert_valid($type->{_types});
    }

    return $type->{_types};
}

# TODO(port): toConfig, toString, toJSON

sub define_types {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLUnionTypeConfig->assert_valid($config);
    }

    my $result = resolve_readonly_array_thunk($config->{types});

    if (ASSERT) {
        ReadonlyArray[GraphQLObjectType]->assert_valid($result);
    }

    return $result
}

type 'GraphQLUnionTypeConfig',
    as Dict[
        name => Str,
        description => Optional[ Str | Undef | Null ],
        types => ThunkReadonlyArray[ GraphQLObjectType ],

        # Optionally provide a custom type resolver function. If one is not provided,
        # the default implementation will call `isTypeOf` on each implementing
        # Object type.
        resolveType => Optional[ GraphQLTypeResolver | Undef | Null ],
        extensions => Optional[ GraphQLUnionTypeExtensions | Undef | Null ], # Readonly
        astNode => Optional[ UnionTypeDefinitionNode | Undef | Null ],
        extensionASTNodes => Optional[ ReadonlyArray[UnionTypeExtensionNode] | Undef | Null ],
    ];

type 'GraphQLUnionTypeNormalizedConfig',
    as Dict[
        extends => GraphQLUnionTypeConfig,
        types => ReadonlyArray[GraphQLUnionTypeConfig],
        extensions => GraphQLUnionTypeExtensions, # Readonly
        extensionASTNodes => ReadonlyArray[UnionTypeExtensionNode],
    ];


# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLEnumTyeExtensions',
    as Map[Str, Unknown];


# Enum Type Definition
#
# Some leaf values of requests and input values are Enums. GraphQL serializes
# Enum values as strings, however internally Enums can be represented by any
# kind of type, often integers.
#
# Example:
#
# ```ts
# const RGBType = new GraphQLEnumType({
#   name: 'RGB',
#   values: {
#     RED: { value: 0 },
#     GREEN: { value: 1 },
#     BLUE: { value: 2 }
#   }
# });
# ```
#
# Note: If a value is not provided in a definition, the name of the enum value
# will be used as its internal value.
type 'GraphQLEnumType',
    as Dict[
        name => Str,
        description => Str | Undef | Null,
        extensions => GraphQLEnumTypeExtensions, # Readonly
        astNode => EnumTypeDefinitionNode | Undef | Null,
        extensionASTNodes => ReadonlyArray[EnumTypeExtensionNode],

        _values => ReadonlyArray[GraphQLEnumValue],
        _valueLookup => Map[Any, GraphQLEnumValue], # FIXME: Need to consider the case where the key of the map is a reference
        _nameLookup => Map[Str, GraphQLEnumValue],
    ];


sub build_graphql_enum_type {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLEnumTypeConfig->assert_valid($config);
    }

    my $type = {};
    $type->{name} = assert_name($config->{name});
    $type->{description} = $config->{description};
    $type->{extensions} = to_obj_map($config->{extensions});
    $type->{astNode} = $config->{astNode};
    $type->{extensionASTNodes} = $config->{extensionASTNodes} // [];

    $type->{_values} = [
        map {
            my $value_name = $_;
            my $value_config = $config->{values}{$value_name};

            my $enum_value = {};
            $enum_value->{name} = assert_enum_value_name($value_name);
            $enum_value->{description} = $value_config->{description};
            $enum_value->{value} = $value_config->{value} // $value_name;
            $enum_value->{deprecationReason} = $value_config->{deprecationReason};
            $enum_value->{extensions} = to_obj_map($value_config->{extensions});
            $enum_value->{astNode} = $value_config->{astNode};
            $enum_value;
        } @{ $config->{values} }
    ];

    $type->{_valueLookup} = {
        map {
            my $enum_value = $_;
            $enum_value->{value} => $enum_value;
        } @{ $type->{_values} }
    };

    $type->{_nameLookup} = {
        map {
            my $enum_value = $_;
            $enum_value->{name} => $enum_value;
        } @{ $type->{_values} }
    };

    if (ASSERT) {
        GraphQLEnumType->assert_valid($type);
    }

    return $type;
}

sub get_values_enum_type {
    my ($type) = @_;

    if (ASSERT) {
        GraphQLEnumType->assert_valid($type);
    }

    return $type->{_values};
}

sub get_value_enum_type {
    my ($type, $name) = @_;

    if (ASSERT) {
        GraphQLEnumType->assert_valid($type);
    }

    my $value = $type->{_nameLookup}{$name};
    if (ASSERT) {
        my $Type = GraphQLEnumValue | Undef | Null;
        $Type->assert_valid($value);
    }
    return $value;
}

sub serialize_enum_type {
    my ($type, $output_value) = @_;

    if (ASSERT) {
        GraphQLEnumType->assert_valid($type);
        Unknown->assert_valid($output_value);
    }

    my $enum_value = $type->{_valueLookup}{$output_value};
    if (!defined $enum_value) {
        croak buile_graphql_error(
            sprintf('Enum "%s" cannot represent value: %s', $type->{name}, inspect($output_value))
        ),
    }

    return $enum_value->{name};
}

sub parse_value_enum_type {
    my ($type, $input_value) = @_;

    if (ASSERT) {
        GraphQLEnumType->assert_valid($type);
        Unknown->assert_valid($input_value);
    }

    if (!Str->check($input_value)) {
        my $value_str = inspect($input_value);
        croak build_graphql_error(
            sprintf('Enum "%s" cannot represent non-string value: %s', $type->{name}, $value_str) .
            did_you_mean_enum_value($type, $value_str)
        );
    }

    my $enum_value = get_value_enum_type($type, $input_value);
    if (Null->check($enum_value)) {
        croak build_graphql_error(
            sprintf('Value "%s" does not exist in "%s" enum.', $input_value, $type->{name}) .
            did_you_mean_enum_value($type, $input_value)
        );
    }

    return $enum_value->{value};
}

sub parse_literal {
    my ($type, $value_node, $_variables) = @_;

    if (ASSERT) {
        GraphQLEnumType->assert_valid($type);
        ValueNode->assert_valid($value_node);

        my $_Variables = Map[Str, Unknown] | Undef | Null;
        $_Variables->assert_valid($_variables);
    }

    # Note: variables will be resolved to a value before calling this function.
    if (!Kind['ENUM']->check($value_node)) {
        my $value_str = print($value_node);
        croak build_graphql_error(
            sprintf('Enum "%s" cannot represent non-enum value: %s.', $type->{name}, $value_str) .
            did_you_mean_enum_value($type, $value_str),
            { nodes => $value_node },
        );
    }

    my $enum_value = get_value_enum_type($type, $value_node->{value});
    if (Null->check($enum_value)) {
        my $value_str = print($value_node);
        croak build_graphql_error(
            sprintf('Value "%s" does not exist in "%s" enum.', $value_str, $type->{name}) .
            did_you_mean_enum_value($type, $value_str),
            { nodes => $value_node },
        );
    }

    return $enum_value->{value};

}

# TODO(port): toConfig, toString, toJSON

sub did_you_mean_enum_value {
    my ($enum_type, $unknown_value_str) = @_;
    my $all_names = [map { $_->{name} } @{ get_values_enum_type($enum_type) }];
    my $suggested_values = suggestion_list($unknown_value_str, $all_names);

    return did_you_mean('the enum value', $suggested_values);
}

type 'GraphQLTypeEnumConfig',
    as Dict[
        name => Str,
        description => Optional[Str],
        values => GraphQLEnumValueConfigMap,
        extensions => Optional[GraphQLEnumTypeExtensions | Undef | Null], # Readonly
        astNode => Optional[EnumTypeDefinitionNode | Undef | Null],
        extensionASTNodes => Optional[ReadonlyArray[EnumTypeExtensionNode] | Undef | Null],
    ];


# FIXME extend GraphQLTypeEnumTypeConfig
type 'GraphQLEnumTypeNormalizedConfig',
    as Dict[
        extensions => GraphQLEnumTypeExtensions, # Readonly
    ];

type 'GraphQLEnumValueConfigMap',
    as Map[Str, GraphQLEnumValueConfig];


# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLEnumValueExtensions',
    as Map[Str, Unknown];

type 'GraphQLEnumValueConfig',
    as Dict[
        description => Optional[Str],
        value => Optional[Unknown],
        deprecationReason => Optional[Str],
        extensions => Optional[GraphQLEnumValueExtensions | Undef | Null], # Readonly
        astNode => Optional[EnumValueDefinitionNode | Undef | Null],
    ];

type 'GraphQLEnumValue',
    as Dict[
        name => Str,
        description => Str | Undef | Null,
        value => Unknown,
        deprecationReason => Str | Undef | Null,
        extensions => GraphQLEnumValueExtensions, # Readonly
        astNode => EnumValueDefinitionNode | Undef | Null,
    ];

# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLInputObjectTypeExtensions',
    as Map[Str, Unknown];

# Input Object Type Definition
#
# An input object defines a structured collection of fields which may be
# supplied to a field argument.
#
# Using `NonNull` will ensure that a value must be provided by the query
#
# Example:
#
# ```ts
# const GeoPoint = new GraphQLInputObjectType({
#   name: 'GeoPoint',
#   fields: {
#     lat: { type: new GraphQLNonNull(GraphQLFloat) },
#     lon: { type: new GraphQLNonNull(GraphQLFloat) },
#     alt: { type: GraphQLFloat, defaultValue: 0 },
#   }
# });
# ```
type 'GraphQLInputObjectType',
    as Dict[
        name => Str,
        description => Str | Undef | Null,
        extensions => GraphQLInputObjectTypeExtensions, # Readonly
        astNode => InputObjectTypeDefinitionNode | Undef | Null,
        extensionASTNodes => ReadonlyArray[InputObjectTypeExtensionNode] | Undef | Null,

        _fields => ThunkObjMap[GraphQLInputField],
    ];

sub build_graphql_input_object_type {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLInputObjectTypeConfig->assert_valid($config);
    }

    my $type = {};
    $type->{name} = assert_name($config->{name});
    $type->{description} = $config->{description};
    $type->{extensions} = to_obj_map($config->{extensions});
    $type->{astNode} = $config->{astNode};
    $type->{extensionASTNodes} = $config->{extensionASTNodes} // [];

    $type->{_fields} = define_input_field_map($config);

    if (ASSERT) {
        GraphQLInputObjectType->assert_valid($type);
    }

    return $type;
}

sub get_fields_input_object_type {
    my ($type) = @_;

    if (ASSERT) {
        GraphQLInputObjectType->assert_valid($type);
    }

    if (ref $type->{_fields} eq 'CODE') {
        $type->{_fields} = $type->{_fields}->();
    }

    if (ASSERT) {
        GraphQLInputFieldMap->assert_valid($type->{_fields});
    }

    return $type->{_fields};
}

# TODO(port): toConfig, toString, toJSON

sub define_input_field_map {
    my ($config) = @_;

    if (ASSERT) {
        GraphQLInputObjectTypeConfig->assert_valid($config);
    }

    my $field_map = resolve_obj_map_thunk($config->{fields});
    my $map = map_value($field_map, sub {
        my ($field_config, $field_name) = @_;

        unless (exists $field_config->{resolve}) {
            croak build_error('%s.%s field has a resolve property, but Input Types cannot define resolvers.', $config->{name}, $field_name);
        }

        return {
            name => assert_name($field_name),
            description => $field_config->{description},
            type => $field_config->{type},
            defaultValue => $field_config->{defaultValue},
            deprecationReason => $field_config->{deprecationReason},
            extensions => to_obj_map($field_config->{extensions}),
            astNode => $field_config->{astNode},
        };
    });

    if (ASSERT) {
        GraphQLInputFieldMap->assert_valid($map);
    }
    return $map;
}

type 'GraphQLInputObjectTypeConfig',
    as Dict[
        name => Str,
        description => Optional[Str | Undef | Null],
        fields => ThunkObjMap[GraphQLInputFieldConfig],
        extensions => Optional[GraphQLInputObjectTypeExtensions | Undef | Null],
        astNode => Optional[InputObjectTypeDefinitionNode | Undef | Null],
        extensionASTNodes => Optional[ReadonlyArray[InputObjectTypeExtensionNode] | Undef | Null],
    ];

# FIXME extends GraphQLNamedTypeConfig
type 'GraphQLInputObjectTypeNormalizedConfig',
    as Dict[
        fields => GraphQLInputFieldConfigMap,
        extensions => GraphQLInputObjectTypeExtensions, # Readonly
        extensionASTNodes => ReadonlyArray[InputObjectTypeExtensionNode],
    ];

# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
type 'GraphQLInputFieldExtensions',
    as Map[Str, Unknown];

type 'GraphQLInputFieldConfig',
    as Dict[
        description => Optional[Str],
        type => GraphQLInputType,
        defaultValue => Optional[Unknown],
        deprecationReason => Optional[Str | Undef | Null],
        extensions => Optional[GraphQLInputFieldExtensions | Undef | Null], # Readonly
        astNode => Optional[InputValueDefinitionNode | Undef | Null],
    ];

type 'GraphQLInputFieldConfigMap',
    as Map[Str, GraphQLInputFieldConfig];

type 'GraphQLInputField',
    as Dict[
        name => Str,
        description => Str | Undef | Null,
        type => GraphQLInputType,
        defaultValue => Unknown,
        deprecationReason => Str | Undef | Null,
        extensions => GraphQLInputFieldExtensions | Undef | Null, # Readonly
        astNode => InputValueDefinitionNode | Undef | Null,
    ];

sub is_required_input_field {
    my ($field) = @_;
    if (ASSERT) {
        GraphQLInputField->assert_valid($field);
    }
    return is_non_null_type($field->{type}) && !defined $field->{defaultValue};
}

type 'GraphQLInputFieldMap',
    as Map[Str, GraphQLInputField];

1;
