package GraphQL::Tiny::Utils::Type;
use strict;
use warnings;

our @EXPORT = qw(
    type
    as
    where
    constraints_of_union
);

use Type::Library -base, -declare => qw(
    Any
    ArrayRef
    Bool
    CodeRef
    Dict
    Enum
    HashRef
    Int
    Map
    Maybe
    Null
    Optional
    ReadonlyArray
    Slurpy
    Str
    Single
    Undef
    Unknown
);

use Type::Utils qw(type as where);
use Types::Standard ();

__PACKAGE__->meta->add_type(Types::Standard::Any);
__PACKAGE__->meta->add_type(Types::Standard::ArrayRef);
__PACKAGE__->meta->add_type(Types::Standard::Bool);
__PACKAGE__->meta->add_type(Types::Standard::CodeRef);
__PACKAGE__->meta->add_type(Types::Standard::Dict);
__PACKAGE__->meta->add_type(Types::Standard::Enum);
__PACKAGE__->meta->add_type(Types::Standard::HashRef);
__PACKAGE__->meta->add_type(Types::Standard::Int);
__PACKAGE__->meta->add_type(Types::Standard::Map);
__PACKAGE__->meta->add_type(Types::Standard::Maybe);
__PACKAGE__->meta->add_type(Types::Standard::Optional);
__PACKAGE__->meta->add_type(Types::Standard::Slurpy);
__PACKAGE__->meta->add_type(Types::Standard::Str);
__PACKAGE__->meta->add_type(Types::Standard::Undef);

type 'Null', as Types::Standard::Undef;

type 'Unknown', as Types::Standard::Defined;

type 'ReadonlyArray', as Types::Standard::ArrayRef,
    name_generator => sub {
        my ($type_name, $param) = @_;
        sprintf '%s[%s]', $type_name, $param;
    },
    constraint_generator => sub {
        my ($param) = @_;
        my $Type = Types::Standard::ArrayRef->of($param);
        return sub { $Type->check(@_) }
    };

type 'Single',
    constraint_generator => sub {
        my ($param) = @_;
        if (Types::Standard::Num->check($param)) {
            return sub { $_ == $param }
        }
        else {
            return sub { $_ eq $param }
        }
    };

sub constraints_of_union :prototype($;$);
sub constraints_of_union :prototype($;$) {
    my ($Union, $Original) = @_;
    $Original //= $Union;

    if (!$Union->isa('Type::Tiny::Union') && $Union->has_parent) {
        return constraints_of_union($Union->parent, $Union);
    }

    die "invalid type: $Original" unless $Union->isa('Type::Tiny::Union');

    my @Types;
    for my $T ( @{ $Union->type_constraints } ) {
        my $Type;
        if ($T->isa('Type::Tiny::_DeclaredType')) {
            my $meta = $Original->has_library ? $Original->library->meta
                     : die "not found meta: $Original";
            $Type = $meta->get_type($T);
        }
        else {
            $Type = $T;
        }

        push @Types => $Type;
    }
    return \@Types
};

1;
