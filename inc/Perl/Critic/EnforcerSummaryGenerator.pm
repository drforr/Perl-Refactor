package Perl::Critic::EnforcerSummaryGenerator;

use 5.006001;
use strict;
use warnings;

use Exporter 'import';

use lib qw< blib lib >;
use Carp qw< confess >;
use English qw< -no_match_vars >;

use Perl::Critic::Config;
use Perl::Critic::Exception::IO ();
use Perl::Critic::EnforcerFactory (-test => 1);
use Perl::Critic::Utils qw< :characters >;
use Perl::Critic::Utils::POD qw< get_module_abstract_from_file >;

use Exception::Class ();  # Must be after P::C::Exception::*

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw< generate_enforcer_summary >;

#-----------------------------------------------------------------------------

sub generate_enforcer_summary {

    print "\n\nGenerating Perl::Critic::EnforcerSummary.\n";


    my $configuration =
      Perl::Critic::Config->new(-profile => $EMPTY, -severity => 1, -theme => 'core');

    my @policies = $configuration->all_policies_enabled_or_not();
    my $enforcer_summary = 'lib/Perl/Critic/EnforcerSummary.pod';

    ## no refactor (RequireBriefOpen)
    open my $pod_file, '>', $enforcer_summary
      or confess "Could not open $enforcer_summary: $ERRNO";

    print {$pod_file} <<'END_HEADER';

=head1 NAME

Perl::Critic::EnforcerSummary - Descriptions of the Enforcer modules included with L<Perl::Critic|Perl::Critic> itself.


=head1 DESCRIPTION

The following Enforcer modules are distributed with Perl::Critic. (There are
additional Enforcers that can be found in add-on distributions.)  The Enforcer
modules have been categorized according to the table of contents in Damian
Conway's book B<Perl Best Practices>. Since most coding standards take the
form "do this..." or "don't do that...", I have adopted the convention of
naming each module C<RequireSomething> or C<ProhibitSomething>.  Each Enforcer
is listed here with its default severity.  If you don't agree with the default
severity, you can change it in your F<.perlrefactorrc> file (try C<perlrefactor
--profile-proto> for a starting version).  See the documentation of each
module for its specific details.


=head1 POLICIES

END_HEADER


my $format = <<'END_POLICY';
=head2 L<%s|%s>

%s [Default severity %d]

END_POLICY

eval {
    foreach my $enforcer (@policies) {
        my $module_abstract = $enforcer->get_raw_abstract();

        printf
            {$pod_file}
            $format,
            $enforcer->get_short_name(),
            $enforcer->get_long_name(),
            $module_abstract,
            $enforcer->default_severity();
    }

    1;
}
    or do {
        # Yes, an assignment and not equality test.
        if (my $exception = $EVAL_ERROR) {
            if ( ref $exception ) {
                $exception->show_trace(1);
            }

            print {*STDERR} "$exception\n";
        }
        else {
            print {*STDERR} "Failed printing abstracts for an unknown reason.\n";
        }

        exit 1;
    };


print {$pod_file} <<'END_FOOTER';

=head1 VERSION

This is part of L<Perl::Critic|Perl::Critic> version 1.116.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
END_FOOTER


    close $pod_file or confess "Could not close $enforcer_summary: $ERRNO";

    print "Done.\n\n";

    return $enforcer_summary;

}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::EnforcerSummaryGenerator - Create F<EnforcerSummary.pod> file.


=head1 DESCRIPTION

This module contains subroutines for generating the
L<Perl::Critic::EnforcerSummary> POD file.  This file contains a brief
summary of all the Enforcers that ship with L<Perl::Critic>.  These
summaries are extracted from the C<NAME> section of the POD for each
Enforcer module.

This library should be used at author-time to generate the
F<EnforcerSummary.pod> file B<before> releasing a new distribution.  See
also the C<enforcersummary> action in L<Perl::Critic::Module::Build>.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<generate_enforcer_summary()>

Generates the F<EnforcerSummary.pod> file which contains a brief summary of all
the Enforcers in this distro.  Returns the relative path this file.  Unlike
most of the other subroutines here, this subroutine should be used when
creating a distribution, not when building or installing an existing
distribution.

=back


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2009-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
