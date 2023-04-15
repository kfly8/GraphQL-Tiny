use strict;
use warnings;
use Test::More;

use GraphQL::Tiny::Inner::TypeLibrary qw(CodeRef);
use GraphQL::Tiny::Language::Ast qw(ASTNode NameNode);

use GraphQL::Tiny::Language::Visitor qw(
    ASTVisitFn
);

use GraphQL::Tiny::Language::Visitor qw(
    get_enter_leave_for_kind
);


subtest 'ASTVisitFn' => sub {
    my $Fn = ASTVisitFn[NameNode];
    ok $Fn->is_subtype_of(CodeRef);
};

subtest 'get_enter_leave_for_kind' => sub {
    pass;
};

done_testing;
