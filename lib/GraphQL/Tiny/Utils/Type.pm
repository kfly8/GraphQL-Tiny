package GraphQL::Tiny::Utils::Type;
use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(
    type as

    Any
    Dict
    Enum
    HashRef
    Int
    Maybe
    Null
    Optional
    ReadonlyArray
    Slurpy
    Str
    Undef
    Unknown
);

use Type::Utils qw(type as);

use Types::Standard qw(
    Any
    ArrayRef
    Dict
    Enum
    HashRef
    Int
    Maybe
    Optional
    Slurpy
    Str
    Undef
);

use constant Null => type 'Null', as Undef;
use constant Unknown => type 'Unknown', as Any;

my $ReadonlyArray = type 'ReadonlyArray', as ArrayRef,
    name_generator => sub {
        my ($type_name, $param) = @_;
        sprintf '%s[%s]', $type_name, $param;
    },
    constraint_generator => sub {
        my ($param) = @_;
        my $Type = ArrayRef->of($param);
        return sub { $Type->check(@_) }
    };

sub ReadonlyArray(;$) {
    my ($type) = @{ $_[0] };
    $ReadonlyArray->of($type);
}

1;
