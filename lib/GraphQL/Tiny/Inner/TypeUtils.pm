package GraphQL::Tiny::Inner::TypeUtils;
use strict;
use warnings;
use feature qw(current_sub);

use Exporter 'import';

our @EXPORT_OK = qw(
    type
    as
    where
    constraints_of_union
    values_of_enum
    value_of_enum
    parameters_of_dict
    key_of_dict
);

use Type::Utils qw(type as where);
use Types::Standard qw(Enum);

# type constraints in a Union type
sub constraints_of_union :prototype($;$) {
    my ($Union, $Original) = @_;
    $Original //= $Union;

    if (!$Union->isa('Type::Tiny::Union') && $Union->has_parent) {
        return __SUB__->($Union->parent, $Original);
    }

    die "invalid type: $Original"
        unless $Union->isa('Type::Tiny::Union');

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
}

# all values in an Enum type
sub values_of_enum :prototype($) {
    my ($Enum) = @_;

    if (!$Enum->isa('Type::Tiny::Enum') && $Enum->has_parent) {
        return __SUB__->($Enum->parent);
    }

    die "invalid type: $Enum"
        unless $Enum->isa('Type::Tiny::Enum');

    $Enum->values;
}

# the first value in an Enum type
sub value_of_enum :prototype($) {
    my ($Enum) = @_;
    values_of_enum($Enum)->[0];
}

# Parameters of Dict type
sub parameters_of_dict :prototype($;$$) {
    my ($Dict, $key, $Original) = @_;
    $Original //= $Dict;

    if ($key) {
        my %params = @{ __SUB__->($Dict, undef, $Original) };
        die "cannot find key: $key in $Original" unless $params{$key};
        return $params{$key};
    }

    if (!$Dict->is_parameterized && $Dict->has_parent) {
        return __SUB__->($Dict->parent, $key, $Original);
    }

    die "invalid type: $Original"
        unless $Dict->is_a_type_of("Dict");

    $Dict->parameters;
}

# Enum type of Dict type keys
sub key_of_dict :prototype($) {
    my ($Dict) = @_;

    my $parameters = parameters_of_dict($Dict);
    my @keys;
    for (my $i = 0; $i < @$parameters; $i++) {
        push @keys => $parameters->[$i] if $i % 2 == 0;
    }
    return Enum[@keys];
}

1;
