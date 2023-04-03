use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Error::LocatedError qw(located_error);
use GraphQL::Tiny::Error::GraphQLError qw(GraphQLError);

subtest 'located_error' => sub {
    subtest 'error message is given' => sub {
        my $error = located_error('some message');
        ok GraphQLError->check($error);
    };

    subtest 'ast node is given' => sub {
        my $ast_node = { kind => 'Name', value => 'foo' };
        my $error = located_error('some message', $ast_node);
        ok GraphQLError->check($error);
    };

    subtest 'ast node and path are given' => sub {
        my $ast_node = { kind => 'Name', value => 'foo' };
        my $path = ['foo', 'bar'];

        my $error = located_error('some message', $ast_node, $path);
        ok GraphQLError->check($error);
    };
};

done_testing;
