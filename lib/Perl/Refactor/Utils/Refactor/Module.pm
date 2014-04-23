package Perl::Refactor::Utils::Refactor::Module;

use 5.006001;
use strict;
use warnings;

use Scalar::Util qw( looks_like_number );

use Readonly;
use List::MoreUtils qw( any );

use Perl::Refactor::Utils::PPI qw{ get_import_list_from_include_statement };
use Perl::Refactor::Utils::Module qw{ get_include_list };

use Exporter 'import';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw(
    enforce_module_bases
    enforce_module_imports
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub _tokens_to_strings {
    my @tokens = @_;
    my @token_words;
    for my $token ( @tokens ) {
        $token->isa('PPI::Token::Number') and
            push @token_words, $token->content;

        $token->isa('PPI::Token::Symbol') and
            push @token_words, $token->content;

        $token->isa('PPI::Token::Quote') and
            push @token_words, $token->string;
    }
    return @token_words;
}

sub _ws_node {
    my ( $whitespace ) = @_;
    $whitespace ||= ' ';
    my $node = PPI::Token::Whitespace->new;
    $node->set_content( $whitespace );
    return $node;
}

sub _comma_node {
    my $node = PPI::Token::Operator->new;
    $node->set_content( ',' );
    return $node;
}

sub _qw_node {
    my ( @words ) = @_;
    my $node = PPI::Token::QuoteLike::Words->new( 'qw' );
    $node->set_content( 'qw< ' . join( ' ', @words ) . ' >' );
    return $node;
}

sub enforce_module_bases {
    my ( $configuration, $include, @base ) = @_;

    return if not $configuration;
    return if not $include;
    return if not @base;

    return if not $include->isa('PPI::Statement::Include');
    return if $include->version;

    my $base = $include->last_element;
    if ( $base->isa('PPI::Token::Structure') and $base->content eq ';' ) {
        $base = $base->sprevious_sibling;
    }

    my $ws = _ws_node( ' ' );
    my $qw = _qw_node( @base );

    if ( $base->isa('PPI::Token::Number') or
         ( $base->isa('PPI::Token::Word') and $base->content eq 'base' ) ) {
        $base->insert_after( $ws );
        $ws->insert_after( $qw );
    }
    else {
        my $comma = _comma_node;

        $base->insert_after( $comma );
        $comma->insert_after( $ws );
        $ws->insert_after( $qw );
    }
    return $include;
}

sub enforce_module_vars {
    my ( $configuration, $include, @var ) = @_;

die "*** enforce_module_vars not done yet\n";
    return if not $configuration;
    return if not $include;
    return if not @var;

    return if not $include->isa('PPI::Statement::Include');
    return if $include->version;

    my $base = $include->last_element;
    if ( $base->isa('PPI::Token::Structure') and $base->content eq ';' ) {
        $base = $base->sprevious_sibling;
    }

    my $ws = _ws_node( ' ' );
    my $qw = _qw_node( @var );

    if ( $base->isa('PPI::Token::Number') or
         ( $base->isa('PPI::Token::Word') and $base->content eq 'vars' ) ) {
        $base->insert_after( $ws );
        $ws->insert_after( $qw );
    }
    else {
        my $comma = _comma_node;

        $base->insert_after( $comma );
        $comma->insert_after( $ws );
        $ws->insert_after( $qw );
    }
    return $include;
}

Readonly::Scalar our $SCOLON => q{;};
Readonly::Scalar our $COMMA => q{,};
Readonly::Scalar our $FCOMMA => q{=>};

sub _is_comma {
    my $element = shift;

    $element->isa('PPI::Token::Operator') and
        $element->content eq $COMMA and
        return 1;

    $element->isa('PPI::Token::Operator') and
        $element->content eq $FCOMMA and
        return 1;

    return;
}

sub _has_existing_import {
    my $include = shift;
    my $first = $include->schild( 0 );
    $first = $first->snext_sibling; # skip 'use'
    $first = $first->snext_sibling; # skip 'Module::Name'

    return 0 unless $first;

    $first = $first->snext_sibling if
        $first->isa('PPI::Token::Number') or
        ( $first->isa('PPI::Token::Quote') and
          looks_like_number( $first->string ) ); # skip v1.2, 4.003, '4.100'

    return 0 unless $first;

    return 0 if $first->isa('PPI::Token::Operator') and
                $first->content eq $SCOLON;

    return 1;
}

sub _has_trailing_comma {
    my $include = shift;
    my $last = $include->last_element;

    $last = $last->sprevious_sibling if
        $last->isa('PPI::Token::Operator') and
        $last->content eq $SCOLON;

    return 1 if $last->isa('PPI::Token::Operator') and
                ( $last->content eq $COMMA or
                  $last->content eq $FCOMMA );

    return 0;
}

sub enforce_module_imports {
    my ( $configuration, $include, @import ) = @_;

    return if not $configuration;
    return if not $include;
    return if not @import;

    return if not $include->isa('PPI::Statement::Include');
    return if $include->version;

    my %existing_imports =
        map { $_ => undef } _tokens_to_strings(
            get_import_list_from_include_statement( $include )
        );
    my @remaining_import;
    for my $import ( @import ) {
        next if exists $existing_imports{$import};
        push @remaining_import, $import;
    }
    
    return $include unless @remaining_import;

    my $base = $include->last_element;
    my $num_tokens = $include->children - 2;
    if ( $base->isa('PPI::Token::Structure') and $base->content eq ';' ) {
        $base = $base->sprevious_sibling;
        $num_tokens--;
    }

    my $ws = _ws_node( ' ' );
    my $qw = _qw_node( @import );

    if ( _has_existing_import( $include ) and
        !_has_trailing_comma( $include ) ) {
        my $comma = _comma_node;

        $base->insert_after( $comma );
        $comma->insert_after( $ws );
        $ws->insert_after( $qw );
    }
    else {
        $base->insert_after( $ws );
        $ws->insert_after( $qw );
    }
    return $include;
}

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Refactor::Utils::Refactor::Module - Utilities for module-level refactoring

=head1 DESCRIPTION

Provides utilities to refactor at the module level


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<enforce_module_imports( $configuration, $include, @import )>

Enforce the inclusion of all C<@import>s in the given
L<PPI::Statement::Include> statement. The default configuration makes the
minimal modifications to the L<PPI::Statement::Include> statement, more
aggressive levels compress C<'foo', 'bar'> into C<< qw< foo bar > >>.

=back


=head1 AUTHOR

Jeff Goff <jgoff@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014 Jeff Goff.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
