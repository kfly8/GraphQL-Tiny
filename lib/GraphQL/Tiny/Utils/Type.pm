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
    Null
    Slurpy
    Str
);

use Type::Utils qw(type as);

use Types::Standard qw(
    Any
    Dict
    Enum
    HashRef
    Int
    Slurpy
    Str
    Undef
);

use constant Null => type 'Null', as Undef;

1;
