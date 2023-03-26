package GraphQL::Tiny::Language::TokenKind;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Type;

use Exporter 'import';

our @EXPORT_OK = qw(TOKEN_KIND TokenKind);

# An exported enum describing the different kinds of tokens that the
# lexer emits.
use constant TOKEN_KIND => {
  SOF => '<SOF>',
  EOF => '<EOF>',
  BANG => '!',
  QUESTION_MARK => '?',
  DOLLAR => '$',
  AMP => '&',
  PAREN_L => '(',
  PAREN_R => ')',
  SPREAD => '...',
  COLON => ':',
  EQUALS => '=',
  AT => '@',
  BRACKET_L => '[',
  BRACKET_R => ']',
  BRACE_L => '{',
  PIPE => '|',
  BRACE_R => '}',
  NAME => 'Name',
  INT => 'Int',
  FLOAT => 'Float',
  STRING => 'String',
  BLOCK_STRING => 'BlockString',
  COMMENT => 'Comment',
};

use constant TokenKind => type 'TokenKind', as Enum[ values %{ TOKEN_KIND() }];

1;
