package Perl::Refactor::Enforcer::Miscellanea::ProhibitUnrestrictedNoRefactor;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Refactor::Utils qw<:severities :booleans>;
use base 'Perl::Refactor::Enforcer';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Unrestricted '## no refactor' annotation};
Readonly::Scalar my $EXPL => q{Only disable the Policies you really need to disable};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Document'            }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $doc, undef ) = @_;

    # If for some reason $doc is not a P::C::Document, then all bets are off
    return if not $doc->isa('Perl::Refactor::Document');

    my @violations = ();
    for my $annotation ($doc->annotations()) {
        if ($annotation->disables_all_policies()) {
            my $elem = $annotation->element();
            push @violations, $self->violation($DESC, $EXPL, $elem);
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords syntaxes

=head1 NAME

Perl::Refactor::Enforcer::Miscellanea::ProhibitUnrestrictedNoRefactor - Forbid a bare C<## no refactor>


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Refactor|Perl::Refactor>
distribution.


=head1 DESCRIPTION

A bare C<## no refactor> annotation will disable B<all> the active Policies.  This
creates holes for other, unintended violations to appear in your code.  It is
better to disable B<only> the particular Policies that you need to get around.
By putting Enforcer names in a comma-separated list after the C<## no refactor>
annotation, then it will only disable the named Policies.  Enforcer names are
matched as regular expressions, so you can use shortened Enforcer names, or
patterns that match several Policies. This Enforcer generates a violation any
time that an unrestricted C<## no refactor> annotation appears.

    ## no refactor                     # not ok
    ## no refactor ''                  # not ok
    ## no refactor ()                  # not ok
    ## no refactor qw()                # not ok

    ## no refactor   (Enforcer1, Enforcer2)  # ok
    ## no refactor   (Enforcer1 Enforcer2)   # ok (can use spaces to separate)
    ## no refactor qw(Enforcer1 Enforcer2)   # ok (the preferred style)


=head1 NOTE

Unfortunately, L<Perl::Refactor|Perl::Refactor> is very sloppy about
parsing the Enforcer names that appear after a C<##no refactor>
annotation.  For example, you might be using one of these
broken syntaxes...

    ## no refactor Enforcer1 Enforcer2
    ## no refactor 'Enforcer1, Enforcer2'
    ## no refactor "Enforcer1, Enforcer2"
    ## no refactor "Enforcer1", "Enforcer2"

In all of these cases, Perl::Refactor will silently disable B<all> Policies,
rather than just the ones you requested.  But if you use the
C<ProhibitUnrestrictedNoRefactor> Enforcer, all of these will generate
violations.  That way, you can track them down and correct them to use
the correct syntax, as shown above in the L<"DESCRIPTION">.  If you've
been using the syntax that is shown throughout the Perl::Refactor
documentation for the last few years, then you should be fine.


=head1 CONFIGURATION

This Enforcer is not configurable except for the standard options.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2008-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
