package GraphQL::Tiny::Language::Ast;
use strict;
use warnings;
use GraphQL::Tiny::Utils::Assert;
use GraphQL::Tiny::Utils::Type;

use Exporter 'import';

our @EXPORT_OK = qw(
    Token
    build_Token

    Location
    build_Location
);

use GraphQL::Tiny::Language::Kinds qw(Kind);
use GraphQL::Tiny::Language::Source qw(Source);
use GraphQL::Tiny::Language::TokenKind qw(TokenKind);


# Represents a range of characters represented by a lexical token
# within a Source.
use constant Token => do {
    my $BaseToken = type 'BaseToken', as Dict[
        # The kind of Token.
        kind => TokenKind,

        # The character offset at which this Node begins.
        start => Int,

        # The character offset at which this Node ends.
        end => Int,

        # The 1-indexed line number on which this Token appears.
        line => Int,

        # The 1-indexed column number at which this Token begins.
        column => Int,

        # For non-punctuation tokens, represents the interpreted value of the token.
        #
        # Note => is undefined for punctuation tokens, but typed as string for
        # convenience in the parser.
        value => Str,

        # Tokens exist as nodes in a double-linked-list amongst all tokens
        # including ignored tokens. <SOF> is always the first node and <EOF>
        # the last.
        prev => HashRef | Null,
        next => HashRef | Null,
    ];

    my $PrevToken;
    $PrevToken = type 'PrevToken', as $BaseToken & sub {
        return 0 if defined $_->{prev} && !$PrevToken->check($_->{prev});
        return 0 if defined $_->{next} && !$BaseToken->check($_->{next});
        return 1;
    };

    my $NextToken;
    $NextToken = type 'NextToken', as $BaseToken & sub {
        return 0 if defined $_->{prev} && !$BaseToken->check($_->{prev});
        return 0 if defined $_->{next} && !$NextToken->check($_->{next});
        return 1;
    };

    my $Token = type 'Token', as $BaseToken & Dict[
        prev => $PrevToken | Null,
        next => $NextToken | Null,
        Slurpy[Any]
    ];

    $Token;
};

sub build_Token {
    my ($kind, $start, $end, $line, $column, $value) = @_;
    my $token = {};
    $token->{kind} = $kind;
    $token->{start} = $start;
    $token->{end} = $end;
    $token->{line} = $line;
    $token->{column} = $column;
    $token->{value} = $value; # TODO(port): Non-null assertion operator
    $token->{prev} = undef;
    $token->{next} = undef;

    if (ASSERT) {
        Token->assert_valid($token);
    }

    return $token;
}

# Contains a range of UTF-8 character offsets and token references that
# identify the region of the source from which the AST derived.
use constant Location =>
    type 'Location',
    as Dict[
        # The character offset at which this Node begins.
        start => Int,

        # The character offset at which this Node ends.
        end => Int,

        # The Token at which this Node begins.
        start_token => Token,

        # The Token at which this Node ends.
        end_token => Token,

        # The Source document the AST represents.
        source => Source,
    ];

sub build_Location {
    my ($start_token, $end_token, $source) = @_;

    if (ASSERT) {
        Token->assert_valid($start_token);
        Token->assert_valid($end_token);
        Source->assert_valid($source);
    }

    my $location = {};
    $location->{start} = $start_token->{start};
    $location->{end} = $end_token->{end};
    $location->{start_token} = $start_token;
    $location->{end_token} = $end_token;
    $location->{source} = $source;
    return $location;
}

1;
