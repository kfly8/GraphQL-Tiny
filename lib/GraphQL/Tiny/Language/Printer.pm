package GraphQL::Tiny::Language::Printer;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeLibrary qw(Null ReadonlyArray Str Undef);

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);

use Exporter 'import';

our @EXPORT_OK = qw(ast_print);

use GraphQL::Tiny::Language::Ast qw(ASTNode);

# TODO port
#use GraphQL::Tiny::Language::Visitor qw(visit);
sub visit { }
#use GraphQL::Tiny::Language::BlockString qw(print_block_string);
sub print_block_string { }
#use GraphQL::Tiny::Language::PrintString qw(print_string);
sub print_string { }


use constant MAX_LINE_LENGTH => 80;

# ASTReducer<string>
use constant PRINT_DOC_AST_REDUCER => {
    Name => { leave => sub { my ($node) = @_; $node->{value} } },
    Variable => { leave => sub { my ($node) = @_; '$' . $node->{name} } },

    # Document

    Document => {
        leave => sub { my ($node) = @_; _join($node->{definitions}, "\n\n") }
    },

    OperationDefinition => {
        leave => sub {
            my ($node) = @_;
            my $varDefs = _wrap('(', _join($node->{variableDefinitions}, ', '), ')');
            my $prefix = _join(
                [
                    $node->{operation},
                    join([$node->{name}, $varDefs]),
                    join($node->{directives}, ' '),
                ],
                ' ',
            );

            # Anonymous queries with no directives or variable definitions can use
            # the query short form.
            return ($prefix eq 'query' ? '' : $prefix . ' ') . $node->{selectionSet};
        }
    },

    VariableDefinition => {
        leave => sub {
            my ($node) = @_;
            $node->{variable} .
            ': ' .
            $node->{type} .
            _wrap(' = ', $node->{defaultValue}) .
            _wrap(' ', join($node->{directives}, ' '))
        }
    },

    SelectionSet => { leave => sub { my ($node) = @_; _block($node->{selections}) } },

    Field => {
        leave => sub {
            my ($node) = @_;
            my $prefix = _join([_wrap('', $node->{alias}, ': '), $node->{name}], '');

            my $argsLine = $prefix . _wrap('(', _join($node->{arguments}, ', '), ')');
            if (length($argsLine) > MAX_LINE_LENGTH) {
                $argsLine = $prefix . _wrap('(\n', _indent(_join($node->{arguments}, '\n')), '\n)');
            }

            return _join([
                $argsLine,
                # Note: Client Controlled Nullability is experimental and may be
                # changed or removed in the future.
                $node->{nullabilityAssertion},
                _wrap(' ', join($node->{directives}, ' ')),
                _wrap(' ', $node->{selectionSet}),
            ]);
        }
    },

    Argument => { leave => sub { my ($node) = @_; $node->{name} . ': ' . $node->{value} } },

    # Nullability Modifiers

    ListNullabilityOperator => {
        leave => sub {
            my ($node) = @_;
            return _join(['[' . $node->{nullabilityAssertion} . ']']);
        }
    },

    NonNullAssertion => {
        leave => sub {
            my ($node) = @_;
            return _join([$node->{nullabilityAssertion}, '!']);
        }
    },

    ErrorBoundary => {
        leave => sub {
            my ($node) = @_;
            return _join([$node->{nullabilityAssertion}, '?']);
        }
    },

    # Fragments

    FragmentSpread => {
        leave => sub {
            my ($node) = @_;
            return '...' . $node->{name} . _wrap(' ', join($node->{directives}, ' '));
        }
    },

    InlineFragment => {
        leave => sub {
            my ($node) = @_;
            return _join([
                '...',
                _wrap('on ', $node->{typeCondition}),
                join($node->{directives}, ' '),
                $node->{selectionSet},
            ], ' ');
        }
    },

    FragmentDefinition => {
        leave => sub {
            my ($node) = @_;
            # Note: fragment variable definitions are experimental and may be changed
            # or removed in the future.
            "fragment @{[ $node->{name} ]}@{[ _wrap('(', _join($node->{variableDefinitions}, ', '), ')') ]} " .
            "on @{[ $node->{typeCondition} ]} @{[ _wrap('', join($node->{directives}, ' '), ' ') ]}" .
            $node->{selectionSet};
        }
    },

    # Value

    IntValue => { leave => sub { my ($node) = @_; $node->{value} } },

    FloatValue => { leave => sub { my ($node) = @_; $node->{value} } },

    StringValue => {
        leave => sub {
            my ($node) = @_;
            return $node->{block} ? print_block_string($node->{value}) : print_string($node->{value});
        }
    },

    BooleanValue => { leave => sub { my ($node) = @_; $node->{value} ? 'true' : 'false' } },

    NullValue => { leave => sub { my ($node) = @_; 'null' } },

    EnumValue => { leave => sub { my ($node) = @_; $node->{value} } },

    ListValue => {
        leave => sub {
            my ($node) = @_;
            return '[' . _join($node->{values}, ', ') . ']';
        }
    },

    ObjectValue => {
        leave => sub {
            my ($node) = @_;
            return '{ ' . _join($node->{fields}, ', ') . ' }';
        }
    },

    ObjectField => { leave => sub { my ($node) = @_; $node->{name} . ': ' . $node->{value} } },

    # Directive

    Directive => {
        leave => sub {
            my ($node) = @_;
            return '@' . $node->{name} . _wrap('(', _join($node->{arguments}, ', '), ')');
        }
    },

    # Type

    NamedType => { leave => sub { my ($node) = @_; $node->{name} } },

    ListType => { leave => sub { my ($node) = @_; '[' . $node->{type} . ']' } },


    NonNullType => { leave => sub { my ($node) = @_; $node->{type} . '!' } },

    # Type System Definitions

    SchemaDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join(['schema', _join($node->{directives}, ' '), _block($node->{operationTypes})], ' ');
        }
    },

    OperationTypeDefinition => {
        leave => sub {
            my ($node) = @_;
            $node->{operation} . ': ' . $node->{type};
        }
    },

    ScalarTypeDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join(['scalar', $node->{name}, _join($node->{directives}, ' ')], ' ');
        }
    },

    ObjectTypeDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join([
                'type',
                $node->{name},
                _wrap('implements ', _join($node->{interfaces}, ' & ')),
                _join($node->{directives}, ' '),
                _block($node->{fields}),
            ], ' ');
        }
    },

    FieldDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            $node->{name} .
            (_has_multiline_items($node->{arguments})
                ? _wrap('(\n', _indent(_join($node->{arguments}, '\n')), '\n)')
                : _wrap('(', _join($node->{arguments}, ', '), ')')) .
            ': ' .
            $node->{type} .
            _wrap(' ', _join($node->{directives}, ' '));
        }
    },

    InputValueDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join(
                [$node->{name} . ': ' . $node->{type}, _wrap('= ', $node->{defaultValue}), _join($node->{directives}, ' ')],
                ' ',
            );
        }
    },

    InterfaceTypeDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join(
                [
                    'interface',
                    $node->{name},
                    _wrap('implements ', _join($node->{interfaces}, ' & ')),
                    _join($node->{directives}, ' '),
                    _block($node->{fields}),
                ],
                ' ',
            );
        }
    },

    UnionTypeDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join(
                ['union', $node->{name}, _join($node->{directives}, ' '), _wrap('= ', _join($node->{types}, ' | '))],
                ' '
            );
        }
    },

    EnumTypeDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join(['enum', $node->{name}, _join($node->{directives}, ' '), _block($node->{values})], ' ');
        }
    },

    EnumValueDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') . _join([$node->{name}, _join($node->{directives}, ' ')], ' ');
        }
    },

    InputObjectTypeDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            _join(['input', $node->{name}, _join($node->{directives}, ' '), _block($node->{fields})], ' ');
        }
    },

    DirectiveDefinition => {
        leave => sub {
            my ($node) = @_;
            _wrap('', $node->{description}, '\n') .
            'directive @' .
            $node->{name} .
            (_has_multiline_items($node->{arguments})
                ? _wrap('(\n', _indent(_join($node->{arguments}, '\n')), '\n)')
                : _wrap('(', _join($node->{arguments}, ', '), ')')) .
            ($node->{repeatable} ? ' repeatable' : '') .
            ' on ' .
            _join($node->{locations}, ' | ');
        }
    },

    SchemaExtension => {
        leave => sub {
            my ($node) = @_;
            _join(
                ['extend schema', _join($node->{directives}, ' '), _block($node->{operationTypes})],
                ' '
            );
        }
    },

    ScalarTypeExtension => {
        leave => sub {
            my ($node) = @_;
            _join(['extend scalar', $node->{name}, _join($node->{directives}, ' ')], ' ');
        }
    },

    ObjectTypeExtension => {
        leave => sub {
            my ($node) = @_;
            _join(
                [
                    'extend type',
                    $node->{name},
                    _wrap('implements ', _join($node->{interfaces}, ' & ')),
                    _join($node->{directives}, ' '),
                    _block($node->{fields}),
                ],
                ' ',
            );
        }
    },

    InterfaceTypeExtension => {
        leave => sub {
            my ($node) = @_;
            _join(
                [
                    'extend interface',
                    $node->{name},
                    _wrap('implements ', _join($node->{interfaces}, ' & ')),
                    _join($node->{directives}, ' '),
                    _block($node->{fields}),
                ],
                ' ',
            );
        }
    },

    UnionTypeExtension => {
        leave => sub {
            my ($node) = @_;
            _join(
                [
                    'extend union',
                    $node->{name},
                    _join($node->{directives}, ' '),
                    _wrap('= ', _join($node->{types}, ' | '))
                ],
                ' ',
            );
        }
    },

    EnumTypeExtension => {
        leave => sub {
            my ($node) = @_;
            _join(['extend enum', $node->{name}, _join($node->{directives}, ' '), _block($node->{values})], ' ');
        }
    },

    InputObjectTypeExtension => {
        leave => sub {
            my ($node) = @_;
            _join(['extend input', $node->{name}, _join($node->{directives}, ' '), _block($node->{fields})], ' ');
        }
    },
};

# Converts an AST into a string, using one set of reasonable
# formatting rules.
sub ast_print {
    my ($ast) = @_;
    return visit($ast, PRINT_DOC_AST_REDUCER);
}

# Given maybeArray, print an empty string if it is null or empty, otherwise
# print all items together separated by separator if provided
sub _join {
  my ($maybe_array, $separator) = @_;
  $separator //= '';

  if (ASSERT) {
      my $MaybeArray = ReadonlyArray[Str | Undef] | Undef | Null;
      $MaybeArray->assert_valid($maybe_array);

      Str->assert_valid($separator);
  }

  return '' unless $maybe_array;
  return join $separator, grep { defined $_ } @$maybe_array;
}


# Given array, print each item on its own line, wrapped in an indented `{ }` block.
sub _block {
  my ($array) = @_;

  if (ASSERT) {
      my $Array = ReadonlyArray[Str | Undef] | Undef | Null;
      $Array->assert_valid($array);
  }

  return _wrap('{\n', _indent(_join($array, '\n')), '\n}');
}


# If maybeString is not null or empty, then wrap with start and end, otherwise print an empty string.
sub _wrap {
    my ($start, $maybe_string, $end) = @_;
    $end //= '';

    if (ASSERT) {
        Str->assert_valid($start);

        my $MaybeString = Str | Undef | Null;
        $MaybeString->assert_valid($maybe_string);

        Str->assert_valid($end);
    }
    return $maybe_string ? $start . $maybe_string . $end : '';
}

sub _indent {
    my ($str) = @_;

    if (ASSERT) {
        Str->assert_valid($str);
    }

    my $next = $str =~ s/\n/\n  /gr;
    return _wrap('  ', $next);
}

sub _has_multiline_items {
    my ($maybe_array) = @_;

    if (ASSERT) {
        my $MaybeArray = ReadonlyArray[Str | Undef] | Undef | Null;
        $MaybeArray->assert_valid($maybe_array);
    }

    return $maybe_array && grep { defined $_ && $_ =~ /\n/ } @$maybe_array;
}

1;
