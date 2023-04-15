package GraphQL::Tiny::Utils::ToObjMap;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeLibrary qw(HashRef Undef);

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);

use Exporter 'import';

our @EXPORT_OK = qw(to_obj_map);

sub to_obj_map {
    my $obj = shift;
    if (ASSERT) {
        my $Type = HashRef | Undef;
        $Type->assert_valid($obj);
    }

    if (!defined $obj) {
        return {};
    }

    return $obj;
}

1;
