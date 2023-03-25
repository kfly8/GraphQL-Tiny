package GraphQL::Tiny::Language::Source;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;

use Exporter 'import';
use Types::Common -types;

our @EXPORT_OK = qw(Source build_Source is_Source);

sub Location() {
    Dict[
        line => PositiveInt,
        column => PositiveInt,
    ]
}

# A representation of source input to GraphQL. The `name` and `locationOffset` parameters are
# optional, but they are useful for clients who store GraphQL documents in source files.
# For example, if the GraphQL input starts at line 40 in a file named `Foo.graphql`, it might
# be useful for `name` to be `"Foo.graphql"` and location to be `{ line: 40, column: 1 }`.
# The `line` and `column` properties in `locationOffset` are 1-indexed.
sub Source() {
    Dict[
        body => Str,
        name => Str,
        location_offset => Location,
    ];
}

sub build_Source {
    my %args = @_;

    my $source = {};
    $source->{body} = $args{body};
    $source->{name} = $args{name};
    $source->{location_offset} = $args{location_offset} // { line => 1, column => 1 };

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
