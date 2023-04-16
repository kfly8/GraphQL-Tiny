package GraphQL::Tiny::Language::Visitor;
use strict;
use warnings;

our @EXPORT_OK = qw(
    visit
    get_enter_leave_for_kind
);

use Type::Library -base, -declare => qw(
    ASTVisitor
    EnterLeaveVisitor
    ASTVisitFn
    KindVisitor
    ASTVisitorKeyMap
    ASTReducer
    ASTReducerFn
    ReducedField
);

use Sub::Util qw(subname);
use List::Util qw(any);
use Scalar::Util qw(blessed);
use GraphQL::Tiny::Utils::DevAssert qw(ASSERT dev_assert);
use GraphQL::Tiny::Language::Ast qw(ASTNode);
use GraphQL::Tiny::Language::Ast qw(is_Node QUERY_DOCUMENT_KEYS);
use GraphQL::Tiny::Language::Kinds qw(Kind);
use GraphQL::Tiny::Inner::TypeUtils qw(
    type
    as
    constraints_of_union
    parameters_of_dict
    value_of_enum
    key_of_dict
);
use GraphQL::Tiny::Inner::TypeLibrary qw(
    Any
    CodeRef
    Dict
    Int
    Map
    Null
    Optional
    ReadonlyArray
    Single
    Str
    Undef
);

# A visitor is comprised of visit functions, which are called on each node
# during the visitor's traversal.
type 'ASTVisitFn', as CodeRef,
    constraint_generator => sub {
        my ($VisitedNode) = @_;

        die "VisitedNode must be extended ASTNode: $VisitedNode" unless _extends_ASTNode($VisitedNode);

        return sub { CodeRef->check(@_) }
    },
    my_methods => {
        signature_for => sub {
            my ($self, $code) = @_;
            return unless ASSERT;

            $self->assert_valid($code);
            my ($VisitedNode) = @{$self->parameters};
            my $subname = subname($code);

            signature_for $subname, (
                positional => [
                    # $node
                    # The current node being visiting.
                    $VisitedNode,

                    # $key
                    # The index or key to this node from the parent node or Array.
                    Str | Int | Undef,

                    # $parent
                    # The parent immediately above this node, which may be an Array.
                    ASTNode | ReadonlyArray[ASTNode] | Undef,

                    # $path
                    ReadonlyArray[Str | Int],

                    # $ancestors
                    # All nodes and Arrays visited before reaching parent of this node.
                    # These correspond to array indices in `path`.
                    # Note: ancestors includes arrays which contain the parent of visited node.
                    ReadonlyArray[ASTNode | ReadonlyArray[ASTNode]],
                ],
            )
        }
    };

type 'EnterLeaveVisitor', as Dict,
    constraint_generator => sub {
        my ($VisitedNode) = @_;

        die "VisitedNode must be extended ASTNode: $VisitedNode" unless _extends_ASTNode($VisitedNode);

        my $Type = Dict[
            enter => Optional[ ASTVisitFn[$VisitedNode] | Undef ],
            leave => Optional[ ASTVisitFn[$VisitedNode] | Undef ],
        ];
        return sub { $Type->check(@_) }
    };

# A visitor is provided to visit, it contains the collection of
# relevant functions to be called during the visitor's traversal.
type 'ASTVisitor', as EnterLeaveVisitor[ASTNode] | KindVisitor;



type 'KindVisitor', do {
    my @dict;
    for my $Node (@{constraints_of_union(ASTNode)}) {
        my $Kind = parameters_of_dict($Node, 'kind');

        my $Visitor = ASTVisitFn[$Node] | EnterLeaveVisitor[$Node];
        push @dict => (value_of_enum($Kind), Optional[$Visitor]);
    }
    as Dict[@dict];
};

type 'ReducedField',
    constaint_generator => sub {
        my ($T, $R) = @_;

        my $RType = blessed($R) && $R->isa('Type::Tiny') ? $R : Single[$R];

        my $Type = $T->is_subtype_of(Null | Undef)
            ? $T
            : $T->is_subtype_of(ReadonlyArray[Any])
            ? ReadonlyArray[$RType]
            : $RType;

        return sub { $Type->check(@_) }
    };

type 'ASTReducerFn', as CodeRef,
    constraint_generator => sub {
        my ($ReducedNode, $R) = @_;

        die "ReducedNode must be extended ASTNode: $ReducedNode" unless _extends_ASTNode($ReducedNode);

        return sub { CodeRef->check(@_) }
    },
    my_methods => {
        signature_for => sub {
            my ($self, $code) = @_;
            return unless ASSERT;

            $self->assert_valid($code);
            my ($ReducedNode, $R) = @{$self->parameters};
            my $subname = subname($code);

            # node: { [K in keyof TReducedNode]: ReducedField<TReducedNode[K], R> },
            my $Node = do {
                my @dict;
                my %params = @{$ReducedNode->parent->parameters};
                for my $key (keys %params) {
                    push @dict => ($key, ReducedField[$params{$key}, $R]);
                }
                Dict[@dict];
            };

            signature_for $subname, (
                # $node
                # The current node being visiting.
                $Node,

                # $key
                # The index or key to this node from the parent node or Array.
                Str | Int | Undef,

                # $parent
                # The parent immediately above this node, which may be an Array.
                ASTNode | ReadonlyArray[ASTNode] | Undef,

                # $path
                # The key path to get to this node from the root node.
                ReadonlyArray[Str | Int],

                # $ancestors
                # All nodes and Arrays visited before reaching parent of this node.
                # These correspond to array indices in `path`.
                # Note: ancestors includes arrays which contain the parent of visited node.
                ReadonlyArray[ASTNode | ReadonlyArray[ASTNode]],
            );
        }
    };

# A KeyMap describes each the traversable properties of each kind of node.
type 'ASTVisitorKeyMap', do {
    my @dict;
    for my $Node (@{constraints_of_union(ASTNode)}) {
        my $Kind = parameters_of_dict($Node, 'kind');
        my $Enum = key_of_dict($Node);
        push @dict => (value_of_enum($Kind), ReadonlyArray[$Enum]);
    }
    as Dict[@dict];
};

# A reducer is comprised of reducer functions which convert AST nodes into
# another form.
type 'ASTReducer', as Dict,
    constraint_generator => sub {
        my ($R) = @_;

        my @dict;
        for my $Node (@{constraints_of_union(ASTNode)}) {
            my $Kind = parameters_of_dict($Node, 'kind');

            my $Reducer = {
                enter => Optional[ ASTReducerFn[$Node] ],
                leave => ASTReducerFn[$Node, $R],
            };
            push @dict => (value_of_enum($Kind), $Reducer);
        }
        my $Type = Dict[@dict];

        return sub { $Type->check(@_) }
    };

# visit() will walk through an AST using a depth-first traversal, calling
# the visitor's enter function at each node in the traversal, and calling the
# leave function after visiting that node and all of its child nodes.
#
# By returning different values from the enter and leave functions, the
# behavior of the visitor can be altered, including skipping over a sub-tree of
# the AST (by returning false), editing the AST by returning a value or null
# to remove the value, or to stop the whole traversal by returning BREAK.
#
# When using visit() to edit an AST, the original AST will not be modified, and
# a new version of the AST with the changes applied will be returned from the
# visit function.
#
# ```ts
# const editedAST = visit(ast, {
#   enter(node, key, parent, path, ancestors) {
#     // @return
#     //   undefined: no action
#     //   false: skip visiting this node
#     //   visitor.BREAK: stop visiting altogether
#     //   null: delete this node
#     //   any value: replace this node with the returned value
#   },
#   leave(node, key, parent, path, ancestors) {
#     // @return
#     //   undefined: no action
#     //   false: no action
#     //   visitor.BREAK: stop visiting altogether
#     //   null: delete this node
#     //   any value: replace this node with the returned value
#   }
# });
# ```
#
# Alternatively to providing enter() and leave() functions, a visitor can
# instead provide functions named the same as the kinds of AST nodes, or
# enter/leave visitors at a named key, leading to three permutations of the
# visitor API:
#
# 1) Named visitors triggered when entering a node of a specific kind.
#
# ```ts
# visit(ast, {
#   Kind(node) {
#     // enter the "Kind" node
#   }
# })
# ```
#
# 2) Named visitors that trigger upon entering and leaving a node of a specific kind.
#
# ```ts
# visit(ast, {
#   Kind: {
#     enter(node) {
#       // enter the "Kind" node
#     }
#     leave(node) {
#       // leave the "Kind" node
#     }
#   }
# })
# ```
#
# 3) Generic visitors that trigger upon entering and leaving any node.
#
# ```ts
# visit(ast, {
#   enter(node) {
#     // enter any node
#   },
#   leave(node) {
#     // leave any node
#   }
# })
# ```

sub visit {
    my ($root, $visitor, $visitor_keys) = @_;

    if (ASSERT) {
        # TODO: port
        #export function visit<N extends ASTNode>(
        #  root: N,
        #  visitor: ASTVisitor,
        #  visitorKeys?: ASTVisitorKeyMap,
        #): N;
        #export function visit<R>(
        #  root: ASTNode,
        #  visitor: ASTReducer<R>,
        #  visitorKeys?: ASTVisitorKeyMap,
        #): R;
        #export function visit(
        #  root: ASTNode,
        #  visitor: ASTVisitor | ASTReducer<any>,
        #  visitorKeys: ASTVisitorKeyMap = QueryDocumentKeys,
        #): any {
    }

    my $enter_leave_map = {};
    for my $kind (@{values_of_enum(Kind)}) {
        $enter_leave_map->{$kind} = get_enter_leave_for_kind($visitor, $kind);
    }
    if (ASSERT) {
        my $EnterLeaveMap = Map[Kind, EnterLeaveVisitor[ASTNode]];
        $EnterLeaveMap->assert_valid($enter_leave_map);
    }

    my $stack = undef;
    my $in_array = ref $root && ref $root eq 'ARRAY';
    my $keys = [$root];
    my $index = -1;
    my $edits = [];
    my $node = $root;
    my $key = undef;
    my $parent = undef;
    my $path = [];
    my $ancestors = [];

    do {
        $index++;
        my $is_leaving = $index == scalar @$keys;
        my $is_edited = $is_leaving && scalar @$edits != 0;
        if ($is_leaving) {
            $key = scalar @$ancestors == 0 ? undef : $path->[-1];
            $node = $parent;
            $parent = pop @$ancestors;
            if ($is_edited) {
                if ($in_array) {
                    $node = [@$node]; # shallow copy

                    my $edit_offset = 0;
                    for my $edit (@$edits) {
                        my ($edit_key, $edit_value) = @$edit;
                        my $array_key = $edit_key - $edit_offset;
                        if (!defined $edit_value) {
                            splice @$node, $array_key, 1;
                            $edit_offset++;
                        } else {
                            $node->[$array_key] = $edit_value;
                        }
                    }
                }
                else {
                    $node = { %$node }; # shallow copy

                    for my $edit (@$edits) {
                        my ($edit_key, $edit_value) = @$edit;
                        $node->{$edit_key} = $edit_value;
                    }
                }
            }

            $index = $stack->{index};
            $keys = $stack->{keys};
            $edits = $stack->{edits};
            $in_array = $stack->{in_array};
            $stack = $stack->{prev};
        }
        elsif ($parent) {
            $key = $in_array ? $index : $keys->[$index];
            $node = $parent->{$key};
            if (!defined $node) {
                next;
            }
            push @$path, $key;
        }

        my $result;
        if (!(ref $node && ref $node eq 'ARRAY')) {
            dev_assert(is_Node($node), "Invalid AST Node: " . inspect($node) . ".");

            my $visit_fn = $is_leaving
                ? $enter_leave_map->{$node->{kind}}->{leave}
                : $enter_leave_map->{$node->{kind}}->{enter};

            $result = $visit_fn ? $visit_fn->($node, $key, $parent, $path, $ancestors) : undef;

            if (_is_BREAK($result)) {
                last;
            }

            if ($result == !!0) {
                if (!$is_leaving) {
                    pop @$path;
                    next;
                }
            }
            elsif (defined $result) {
                push @$edits, [$key, $result];
                if (!$is_leaving) {
                    if (is_Node($result)) {
                        $node = $result;
                    }
                    else {
                        pop @$path;
                        next;
                    }
                }
            }
        }

        if (!defined $result && $is_edited) {
            push @$edits, [$key, $node];
        }

        if ($is_leaving) {
            pop @$path;
        }
        else {
            $stack = {
                in_array => $in_array,
                index => $index,
                keys => $keys,
                edits => $edits,
                prev => $stack,
            };
            $in_array = ref $node && ref $node eq 'ARRAY';
            $keys = $in_array ? $node : ($visitor_keys->{$node->{kind}} // []);
            $index = -1;
            $edits = [];
            if ($parent) {
                push @$ancestors, $parent;
            }
            $parent = $node;
        }
    } while (defined $stack);

    if (scalar @$edits != 0) {
        # New root
        return $edits->[-1]->[1];
    }

    return $root;
}

# Given a visitor instance and a node kind, return EnterLeaveVisitor for that kind.
sub get_enter_leave_for_kind {
    my ($visitor, $kind) = @_;

    if (ASSERT) {
        ASTVisitor->assert_valid($visitor);
        Kind->assert_valid($kind);
    }

    my $kind_visitor = $visitor->{$kind};
    if (ASSERT) {
        my $KindVisitor = ASTVisitFn[ASTNode] | EnterLeaveVisitor[ASTNode] | Undef;
        $KindVisitor->assert_valid($kind_visitor);
    }

    my $result;
    if (ref $kind_visitor eq 'HASH') {
        # { Kind: { enter() {}, leave() {} } }
        $result = $kind_visitor;
    } elsif (ref $kind_visitor eq 'CODE') {
        # { Kind() {} }
        $result = { enter => $kind_visitor, leave => undef };
    }
    else {
        # { enter() {}, leave() {} }
        $result = { enter => $visitor->{enter}, leave => $visitor->{leave} };
    }

    if (ASSERT) {
        my $EnterLeaveVisitor = EnterLeaveVisitor[ASTNode];
        $EnterLeaveVisitor->assert_valid($result);
    }

    return $result;
}



sub _extends_ASTNode {
    my ($Node) = @_;

    return 1 if $Node eq ASTNode;
    my $Nodes = ASTNode->parent->type_constraints;
    return any { $_ eq $Node } @{$Nodes};
}

sub _is_BREAK {
    my ($result) = @_;

    ref $result && ref $result eq 'HASH' && %{$result} == 0;
}

1;
