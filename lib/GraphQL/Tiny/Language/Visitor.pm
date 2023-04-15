package GraphQL::Tiny::Language::Visitor;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeUtils qw(
    type
    as
    constraints_of_union
    parameters_of_dict
    value_of_enum
    key_of_dict
);
use GraphQL::Tiny::Inner::TypeLibrary -all;

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);

use GraphQL::Tiny::Language::Ast qw(ASTNode);
use GraphQL::Tiny::Language::Ast qw(is_Node QUERY_DOCUMENT_KEYS);
use GraphQL::Tiny::Language::Kinds qw(Kind);

use Sub::Util qw(subname);
use List::Util qw(any);
use Scalar::Util qw(blessed);

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


sub visit {
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

1;
