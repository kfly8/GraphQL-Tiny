use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Utils::Type qw(CodeRef);
use GraphQL::Tiny::Language::Ast qw(ASTNode NameNode);

use GraphQL::Tiny::Language::Visitor qw(
    ASTVisitFn
);

subtest 'ASTVisitFn' => sub {
    my $Fn = ASTVisitFn[NameNode];
    ok $Fn->is_subtype_of(CodeRef);
};

done_testing;
