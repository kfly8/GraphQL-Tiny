package GraphQL::Tiny::Language::Source;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type;

use Carp qw(croak);
use Exporter 'import';

our @EXPORT_OK = qw(Source build_Source is_Source);

use constant Location =>
    type 'Location',
        as Dict[
            line => Int,
            column => Int,
        ];

# A representation of source input to GraphQL. The `name` and `locationOffset` parameters are
# optional, but they are useful for clients who store GraphQL documents in source files.
# For example, if the GraphQL input starts at line 40 in a file named `Foo.graphql`, it might
# be useful for `name` to be `"Foo.graphql"` and location to be `{ line: 40, column: 1 }`.
# The `line` and `column` properties in `locationOffset` are 1-indexed.
use constant Source =>
    type 'Source',
        as Dict[
            body => Str,
            name => Str,
            location_offset => Location,
        ];

sub build_Source {
    my ($body, $name, $location_offset) = @_;

    my $source = {};
    $source->{body} = $body;
    $source->{name} = $name // 'GraphQL request';
    $source->{location_offset} = $location_offset // { line => 1, column => 1 };

    if (ASSERT) {
        unless ($source->{location_offset}{line} > 0) {
            croak 'line in locationOffset is 1-indexed and must be positive.',
        }

        unless ($source->{location_offset}{column} > 0) {
            croak 'column in locationOffset is 1-indexed and must be positive.',
        }

        Source->assert_valid($source);
    }

    return $source;
}

sub is_Source {
    my ($source) = @_;
    Source->check($source);
}

1;
