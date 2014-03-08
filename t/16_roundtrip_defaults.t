#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::Config;
use Perl::Critic::ProfilePrototype;
use Perl::Critic::Utils qw{ :characters :severities };

use Test::Deep;
use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

my $default_configuration =
    Perl::Critic::Config->new(
        -profile => $EMPTY,
        -severity => 1,
        -theme => 'core',
    );
my @default_policies = $default_configuration->policies();

my $enforcer_test_count;

$enforcer_test_count = 4 * @default_policies;
foreach my $enforcer (@default_policies) {
    if (
            $enforcer->parameter_metadata_available()
        and not $enforcer->isa('Perl::Critic::Policy::CodeLayout::RequireTidyCode')
    ) {
        $enforcer_test_count += scalar @{$enforcer->get_parameters()};
    }
}
my $test_count = 18 + $enforcer_test_count;
plan tests => $test_count;

#-----------------------------------------------------------------------------

my $profile_generator =
    Perl::Critic::ProfilePrototype->new(
        -policies                   => \@default_policies,
        '-comment-out-parameters'   => 0,
        -config                     => $default_configuration,
    );
my $profile = $profile_generator->to_string();

my $derived_configuration =
    Perl::Critic::Config->new( -profile => \$profile );

#-----------------------------------------------------------------------------

my @derived_include = $derived_configuration->include();
my @default_include = $default_configuration->include();
cmp_deeply(
    \@derived_include,
    \@default_include,
    'include',
);

#-----------------------------------------------------------------------------

my @derived_exclude = $derived_configuration->exclude();
my @default_exclude = $default_configuration->exclude();
cmp_deeply(
    \@derived_exclude,
    \@default_exclude,
    'exclude',
);

#-----------------------------------------------------------------------------

my @derived_single_enforcer = $derived_configuration->single_enforcer();
my @default_single_enforcer = $default_configuration->single_enforcer();
cmp_deeply(
    \@derived_single_enforcer,
    \@default_single_enforcer,
    'single_enforcer',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->force(),
    $default_configuration->force(),
    'force',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->only(),
    $default_configuration->only(),
    'only',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->profile_strictness(),
    $default_configuration->profile_strictness(),
    'force',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color(),
    $default_configuration->color(),
    'color',
);

#-----------------------------------------------------------------------------

cmp_ok(
    $derived_configuration->severity(),
    q<==>,
    $default_configuration->severity(),
    'severity',
);

#-----------------------------------------------------------------------------

cmp_ok(
    $derived_configuration->top(),
    q<==>,
    $default_configuration->top(),
    'top',
);

#-----------------------------------------------------------------------------

cmp_ok(
    $derived_configuration->verbose(),
    q<==>,
    $default_configuration->verbose(),
    'verbose',
);

#-----------------------------------------------------------------------------

cmp_deeply(
    $derived_configuration->theme(),
    $default_configuration->theme(),
    'theme',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_severity_highest(),
    $default_configuration->color_severity_highest(),
    'color_severity_highest',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_severity_high(),
    $default_configuration->color_severity_high(),
    'color_severity_high',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_severity_medium(),
    $default_configuration->color_severity_medium(),
    'color_severity_medium',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_severity_low(),
    $default_configuration->color_severity_low(),
    'color_severity_low',
);

#-----------------------------------------------------------------------------

is(
    $derived_configuration->color_severity_lowest(),
    $default_configuration->color_severity_lowest(),
    'color_severity_lowest',
);

#-----------------------------------------------------------------------------

my @derived_program_extensions = $derived_configuration->program_extensions();
my @default_program_extensions = $default_configuration->program_extensions();
cmp_deeply(
    \@derived_program_extensions,
    \@default_program_extensions,
    'program_extensions',
);

#-----------------------------------------------------------------------------

my @derived_policies = $derived_configuration->policies();

my $enforcer_counts_match =
    is(
        scalar @derived_policies,
        scalar @default_policies,
        'same enforcer count'
    );

SKIP: {
    skip
        q{because there weren't the same number of policies},
            $enforcer_test_count
        if not $enforcer_counts_match;

    for (my $x = 0; $x < @default_policies; $x++) { ## no critic (ProhibitCStyleForLoops)
        my $derived_enforcer = $derived_policies[$x];
        my $default_enforcer = $default_policies[$x];

        is(
            $derived_enforcer->get_short_name(),
            $default_enforcer->get_short_name(),
            'enforcer names match',
        );
        is(
            $derived_enforcer->get_maximum_violations_per_document(),
            $default_enforcer->get_maximum_violations_per_document(),
            $default_enforcer->get_short_name() . ' maximum violations per document match',
        );
        is(
            $derived_enforcer->get_severity(),
            $default_enforcer->get_severity(),
            $default_enforcer->get_short_name() . ' severities match',
        );
        is(
            $derived_enforcer->get_themes(),
            $default_enforcer->get_themes(),
            $default_enforcer->get_short_name() . ' themes match',
        );

        if (
                $default_enforcer->parameter_metadata_available()
            and not $default_enforcer->isa('Perl::Critic::Policy::CodeLayout::RequireTidyCode')
        ) {
            # Encapsulation violation alert!
            foreach my $parameter ( @{$default_enforcer->get_parameters()} ) {
                my $parameter_name =
                    $default_enforcer->__get_parameter_name( $parameter );

                cmp_deeply(
                    $derived_enforcer->{$parameter_name},
                    $default_enforcer->{$parameter_name},
                    $default_enforcer->get_short_name()
                        . $SPACE
                        . $parameter_name
                        . ' match',
                );
            }
        }
    }
}


#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
