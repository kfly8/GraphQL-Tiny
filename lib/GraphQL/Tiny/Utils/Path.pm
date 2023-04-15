package GraphQL::Tiny::Utils::Path;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeUtils qw(type as);
use GraphQL::Tiny::Inner::TypeLibrary -all;

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT);

use Exporter 'import';

our @EXPORT_OK = qw(
    add_path
    path_to_array
);

use Type::Library -base, -declare => qw(Path);

type 'Path' => as Dict[
  prev => Path | Undef,
  key => Str | Int,
  typename => Str | Undef,
];

# Given a Path and a key, return a new Path containing the new key.
sub add_path {
    my ($prev, $key, $typename) = @_;
    if (ASSERT) {
        my $Prev = Path | Undef;
        $Prev->assert_valid($prev);

        my $Key = Str | Int;
        $Key->assert_valid($key);

        my $Typename = Str | Undef;
        $Typename->assert_valid($typename);
    }

    my $path = { prev => $prev, key => $key, typename => $typename };
    if (ASSERT) {
        Path->assert_valid($path);
    }
    return $path;
}

# Given a Path, return an Array of the path keys.
sub path_to_array {
    my ($path) = @_;

    my $flattened = [];
    my $curr = $path;
    while ($curr) {
        push @$flattened, $curr->{key};
        $curr = $curr->{prev};
    }
    return [reverse @$flattened];
}

1;
