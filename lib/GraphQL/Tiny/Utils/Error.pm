package GraphQL::Tiny::Utils::Error;
use strict;
use warnings;
use GraphQL::Tiny::Inner::TypeUtils qw(type as);
use GraphQL::Tiny::Inner::TypeLibrary -all;

our @EXPORT_OK = qw(build_error to_error);

use Carp qw(longmess);
use Data::Dumper ();

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

    return $error;
}

sub to_error {
    my ($thrown_value) = @_;

    return $thrown_value if Error->check($thrown_value);

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse  = 1;

    my $message = 'Unexpected error value: ' . Data::Dumper::Dumper($thrown_value);
    my $error = build_error($message, 'NonErrorThrown');
    $error->{thrown_value} = $thrown_value;
    return $error;
}

1;
