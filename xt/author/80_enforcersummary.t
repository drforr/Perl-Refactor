#!perl

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;

use File::Spec;
use List::MoreUtils qw(any);

use Perl::Refactor::EnforcerFactory ( -test => 1 );
use Perl::Refactor::TestUtils qw{ bundled_enforcer_names };

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

my $summary_file =
    File::Spec->catfile( qw< lib Perl Refactor EnforcerSummary.pod > );
if (open my ($fh), '<', $summary_file) {

    my $content = do {local $INPUT_RECORD_SEPARATOR=undef; <$fh> };
    close $fh or confess "Couldn't close $summary_file: $OS_ERROR";

    my @enforcer_names = bundled_enforcer_names();
    my @summaries    = $content =~ m/^=head2 [ ]+ L<[\w:]+[|]([\w:]+)>/gxms;
    plan( tests => 2 + 2 * @enforcer_names );

    my %num_summaries;
    for my $summary (@summaries) {
        ++$num_summaries{$summary};
    }
    if (!ok(@summaries == keys %num_summaries, 'right number of summaries')) {
        for my $enforcer_name (sort keys %num_summaries) {
            next if 1 == $num_summaries{$enforcer_name};
            diag('Duplicate summary for ' . $enforcer_name);
        }
    }

    my $profile = Perl::Refactor::UserProfile->new();
    my $factory = Perl::Refactor::EnforcerFactory->new( -profile => $profile );
    my %found_enforcers = map { ref $_ => $_ } $factory->create_all_enforcers();

    my %descriptions = $content =~ m/^=head2 [ ]+ L<[\w:]+[|]([\w:]+)>\n\n([^\n]+)/gxms;
    for my $enforcer_name (keys %descriptions) {
        my $severity;
        if (
            $descriptions{$enforcer_name} =~ s/ [ ] \[ Default [ ] severity [ ] (\d+) \] //xms
        ) {
            $severity = $1;
        }
        else {
            $severity = '<unknown>';
        }

        $descriptions{$enforcer_name} = {
            desc => $descriptions{$enforcer_name},
            severity => $severity,
        };
    }

    for my $enforcer_name ( @enforcer_names ) {
        my $label = qq{EnforcerSummary.pod has "$enforcer_name"};
        my $has_summary = delete $num_summaries{$enforcer_name};
        is( $has_summary, 1, $label );

        my $summary_severity = $descriptions{$enforcer_name}->{severity};
        my $real_severity = $found_enforcers{$enforcer_name} &&
          $found_enforcers{$enforcer_name}->default_severity;
        is( $summary_severity, $real_severity, "severity for $enforcer_name" );
    }

    if (!ok(0 == keys %num_summaries, 'no extra summaries')) {
        for my $enforcer_name (sort keys %num_summaries) {
            diag('Extraneous summary for ' . $enforcer_name);
        }
    }
}
else {
    plan 'no_plan';
    fail qq<Cannot open "$summary_file": $ERRNO>;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/80_enforcersummary.t.without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
