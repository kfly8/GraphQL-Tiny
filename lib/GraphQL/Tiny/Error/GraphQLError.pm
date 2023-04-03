package GraphQL::Tiny::Error::GraphQLError;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type -all;
use GraphQL::Tiny::Utils::Error qw(Error build_error);

our @EXPORT_OK = qw(build_graphql_error);

use Type::Library -base, -declare => qw(
    GraphQLErrorExtensions
    GraphQLErrorOptions
    GraphQLError
);

use GraphQL::Tiny::Language::Ast qw(ASTNode);
use GraphQL::Tiny::Language::Source qw(Source);
use GraphQL::Tiny::Language::Location qw(SourceLocation get_location);

#
# Custom extensions
#
# @remarks
# Use a unique identifier name for your extension, for example the name of
# your library or project. Do not use a shortened identifier as this increases
# the risk of conflicts. We recommend you add at most one extension field,
# an object which can contain all the values you need.
#
type 'GraphQLErrorExtensions',
    as Map[
        Str, Unknown
    ];

type 'GraphQLErrorOptions',
    as Dict[
        nodes => Optional[ ReadonlyArray[ASTNode] | ASTNode | Null | Undef ],
        source => Optional[ Maybe[Source] ],
        positions => Optional[ Maybe[ReadonlyArray[Int]] ],
        path => Optional[ Maybe[ReadonlyArray[Str | Int]] ],
        originalError => Optional[ Maybe[ Error & Dict[extensions => Optional[Unknown], Slurpy[Any]] ] ],
        extensions => Optional[ Maybe[GraphQLErrorExtensions] ],
    ];

#
# A GraphQLError describes an Error found during the parse, validate, or
# execute phases of performing a GraphQL operation. In addition to a message
# and stack trace, it also includes information about the locations in a
# GraphQL document and/or execution result that correspond to the Error.
#
type 'GraphQLError',
   as Error & Dict[
       #
       # An array of `{ line, column }` locations within the source GraphQL document
       # which correspond to this error.
       #
       # Errors during validation often contain multiple locations, for example to
       # point out two things with the same name. Errors during execution include a
       # single location, the field which produced the error.
       #
       # Enumerable, and appears in the result of JSON.stringify().
       #
       locations => ReadonlyArray[SourceLocation] | Undef,

       #
       # An array describing the JSON-path into the execution response which
       # corresponds to this error. Only included for errors during execution.
       #
       # Enumerable, and appears in the result of JSON.stringify().
       #
       path => ReadonlyArray[Str | Int] | Undef,

       #
       # An array of GraphQL AST Nodes corresponding to this error.
       #
       nodes => ReadonlyArray[ASTNode] | Undef,

       #
       # The source GraphQL document for the first location of this error.
       #
       # Note that if this Error represents more than one node, the source may not
       # represent nodes after the first node.
       #
       source => Source | Undef,

       #
       # An array of character offsets within the source GraphQL document
       # which correspond to this error.
       #
       positions => ReadonlyArray[Int] | Undef,

       #
       # The original error thrown from a field resolver during execution.
       #
       originalError => Error | Undef,

       #
       # Extension fields to add to the formatted error.
       #
       extensions => GraphQLErrorExtensions,

       Slurpy[Any],
   ];

sub build_graphql_error {
    my ($message, $options) = @_;
    $options //= {};

    if (ASSERT) {
        Str->assert_valid($message);
        GraphQLErrorOptions->assert_valid($options);
    }

    my ($nodes, $source, $positions, $path, $original_error, $extensions) = @{$options}{qw/
        nodes source positions path originalError extensions
    /};

    my $error = build_error($message, 'GraphQLError');

    $error->{path} = $path // undef;
    $error->{originalError} = $original_error // undef;

    # Compute list of blame nodes.
    $error->{nodes} = undefined_if_empty(
        ref $nodes && ref $nodes eq 'ARRAY' ? $nodes : defined $nodes ? [$nodes] : undef
    );

    my $node_locations = undefined_if_empty(
        defined $error->{nodes} ? [ map { defined $_->{loc} ? $_->{loc} : () } @{$error->{nodes}} ] : undef
    );

    # Compute locations in the source for the given nodes/positions.
    $error->{source} = $source // do { $node_locations ? $node_locations->[0]->{source} : undef };

    $error->{positions} = $positions // do { $node_locations ? [ map { $_->{start} } @{$node_locations} ] : undef };

    $error->{locations} =
        $positions && $source
          ? [ map { get_location($source, $_) } @{$positions} ]
          : $node_locations ? [ map { get_location($_->{source}, $_->{start}) } @{$node_locations} ] : undef;

    my $original_extensions = ref $original_error && ref $original_error eq 'HASH' && $original_error->{extensions}
        ? $original_error->{extensions}
        : undef;

    $error->{extensions} = $extensions // $original_extensions // {};

    if (ASSERT) {
        GraphQLError->assert_valid($error);
    }

    return $error;
}

sub undefined_if_empty {
    my ($array) = @_;
    return !defined $array || @$array == 0 ? undef : $array;
}

1;
