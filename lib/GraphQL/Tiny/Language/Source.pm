package GraphQL::Tiny::Language::Source;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeUtils qw(type as);
use GraphQL::Tiny::Inner::TypeLibrary -all;

use GraphQL::Tiny::Utils::DevAssert qw(ASSERT dev_assert);

our @EXPORT_OK = qw(build_source is_Source);

use Type::Library -base, -declare => qw(Source);

my $Location = type 'Location',
    as Dict[
        line => Int,
        column => Int,
    ];

# A representation of source input to GraphQL. The `name` and `locationOffset` parameters are
# optional, but they are useful for clients who store GraphQL documents in source files.
# For example, if the GraphQL input starts at line 40 in a file named `Foo.graphql`, it might
# be useful for `name` to be `"Foo.graphql"` and location to be `{ line: 40, column: 1 }`.
# The `line` and `column` properties in `locationOffset` are 1-indexed.
type 'Source',
    as Dict[
        body => Str,
        name => Str,
        locationOffset => $Location,
    ];

sub build_source {
    my ($body, $name, $location_offset) = @_;

    if (ASSERT) {
        Str->assert_valid($body);
        Str->assert_valid($name) if defined $name;
        $Location->assert_valid($location_offset) if defined $location_offset;
    }

    my $source = {};
    $source->{body} = $body;
    $source->{name} = $name // 'GraphQL request';
    $source->{locationOffset} = $location_offset // { line => 1, column => 1 };

    dev_assert(
        $source->{locationOffset}{line} > 0,
        'line in locationOffset is 1-indexed and must be positive.',
    );

    dev_assert(
        $source->{locationOffset}{column} > 0,
        'column in locationOffset is 1-indexed and must be positive.',
    );

    if (ASSERT) {
        Source->assert_valid($source);
    }

    return $source;
}

sub is_Source {
    my ($source) = @_;
    Source->check($source);
}

1;
