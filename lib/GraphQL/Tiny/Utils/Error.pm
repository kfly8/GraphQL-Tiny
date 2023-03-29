package GraphQL::Tiny::Utils::Error;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type -all;

our @EXPORT_OK = qw(build_error);

use Carp qw(longmess);

use Type::Library -base, -declare => qw(Error);

type 'Error',
    as Dict[
        name    => Str,
        message => Str,
        stack   => Str,
        Slurpy[Any],
    ];

sub build_error {
    my ($message, $name) = @_;
    $name //= 'Error';

    my $error = {
        name => $name,
        message => $message,
        stack => longmess(),
    };

    if (ASSERT) {
        Error->assert_valid($error);
    }

    return $error;
}

1;
