package Perl::Refactor::Enforcer::RegularExpressions::ProhibitEnumeratedClasses;

use 5.006001;
use strict;
use warnings;

use Carp qw(carp);
use English qw(-no_match_vars);
use List::MoreUtils qw(all);
use Readonly;

use Perl::Refactor::Utils qw{ :booleans :severities hashify };

use base 'Perl::Refactor::Enforcer';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use named character classes};
Readonly::Scalar my $EXPL => [248];

Readonly::Array my @PATTERNS => (  # order matters: most to least specific
   [q{ },'\\t','\\r','\\n']      => ['\\s', '\\S'],
   ['A-Z','a-z','0-9','_']       => ['\\w', '\\W'], # RT 69322
   ['A-Z','a-z']                 => ['[[:alpha:]]','[[:^alpha:]]'],
   ['A-Z']                       => ['[[:upper:]]','[[:^upper:]]'],
   ['a-z']                       => ['[[:lower:]]','[[:^lower:]]'],
   ['0-9']                       => ['\\d','\\D'],
   ['\w']                        => [undef, '\\W'],
   ['\s']                        => [undef, '\\S'],
);

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                    }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic unicode ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------


sub violates {
    my ( $self, $elem, $document ) = @_;

    # optimization: don't bother parsing the regexp if there are no character classes
    return if $elem !~ m/\[/xms;

    my $re = $document->ppix_regexp_from_element( $elem ) or return;
    $re->failures() and return;

    my $anyofs = $re->find( 'PPIx::Regexp::Structure::CharClass' )
        or return;
    foreach my $anyof ( @{ $anyofs } ) {
        my $violation;
        $violation = $self->_get_character_class_violations( $elem, $anyof )
            and return $violation;
    }

    return;  # OK
}

sub _get_character_class_violations {
    my ($self, $elem, $anyof) = @_;

    my %elements;
    foreach my $element ( $anyof->children() ) {
        $elements{ _fixup( $element ) } = 1;
    }

    for (my $i = 0; $i < @PATTERNS; $i += 2) {  ##no refactor (CStyleForLoop)
        if (all { exists $elements{$_} } @{$PATTERNS[$i]}) {
            my $neg = $anyof->negated();
            my $improvement = $PATTERNS[$i + 1]->[$neg ? 1 : 0];
            next if !defined $improvement;

            if ($neg && ! defined $PATTERNS[$i + 1]->[0]) {
                # the [^\w] => \W rule only applies if \w is the only token.
                # that is it does not apply to [^\w\s]
                next if 1 != scalar keys %elements;
            }

            my $orig = join q{}, '[', ($neg ? q{^} : ()), @{$PATTERNS[$i]}, ']';
            return $self->violation( $DESC . " ($orig vs. $improvement)", $EXPL, $elem );
        }
    }

    return;  # OK
}

Readonly::Hash my %ORDINALS => (
    ord "\n"    => '\\n',
    ord "\f"    => '\\f',
    ord "\r"    => '\\r',
    ord q< >    => q< >,
);

sub _fixup {
    my ( $element ) = @_;
    if ( $element->isa( 'PPIx::Regexp::Token::Literal' ) ) {
        my $ord = $element->ordinal();
        exists $ORDINALS{$ord} and return $ORDINALS{$ord};
        return $element->content();
    } elsif ( $element->isa( 'PPIx::Regexp::Node' ) ) {
        return join q{}, map{ _fixup( $_ ) } $element->elements();
    } else {
        return $element->content();
    }
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Refactor::Enforcer::RegularExpressions::ProhibitEnumeratedClasses - Use named character classes instead of explicit character lists.


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Refactor|Perl::Refactor>
distribution.


=head1 DESCRIPTION

This enforcer is not for everyone!  If you are working in pure ASCII,
then disable it now or you may see some false violations.

On the other hand many of us are working in a multilingual world with
an extended character set, probably Unicode.  In that world, patterns
like C<m/[A-Z]/> can be a source of bugs when you really meant
C<m/\p{IsUpper}/>.  This enforcer catches a selection of possible
incorrect character class usage.

Specifically, the patterns are:

B<C<[\t\r\n\f\ ]>> vs. B<C<\s>>

B<C<[\t\r\n\ ]>> vs. B<C<\s>>   (because many people forget C<\f>)

B<C<[A-Za-z0-9_]>> vs. B<C<\w>>

B<C<[A-Za-z]>> vs. B<C<\p{IsAlphabetic}>>

B<C<[A-Z]>> vs. B<C<\p{IsUpper}>>

B<C<[a-z]>> vs. B<C<\p{IsLower}>>

B<C<[0-9]>> vs. B<C<\d>>

B<C<[^\w]>> vs. B<C<\W>>

B<C<[^\s]>> vs. B<C<\S>>


=head1 CONFIGURATION

This Enforcer is not configurable except for the standard options.


=head1 CREDITS

Initial development of this enforcer was supported by a grant from the
Perl Foundation.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
