use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Language::Source qw(build_source);
use GraphQL::Tiny::Error::GraphQLError qw(GraphQLError);

use GraphQL::Tiny::Error::SyntaxError qw(syntax_error);

subtest 'syntax_error' => sub {
    my $source = build_source('query { foo }');

    my $error = syntax_error($source, 123, 'some message');

    ok GraphQLError->check($error), 'is a GraphQLError';

    is $error->{message}, 'Syntax Error: some message', 'message';
    is $error->{source}, $source, 'source';
    is $error->{positions}->[0], 123, 'positions';
};

done_testing;
