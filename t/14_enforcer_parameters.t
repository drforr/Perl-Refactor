#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::UserProfile qw();
use Perl::Critic::EnforcerFactory (-test => 1);
use Perl::Critic::EnforcerParameter qw{ $NO_DESCRIPTION_AVAILABLE };
use Perl::Critic::Utils qw( enforcer_short_name );
use Perl::Critic::TestUtils qw(bundled_enforcer_names);

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

use Test::More; #plan set below!

Perl::Critic::TestUtils::block_perlrefactorrc();

#-----------------------------------------------------------------------------
# This program proves that each enforcer that ships with Perl::Critic overrides
# the supported_parameters() method and, assuming that the enforcer is
# configurable, that each parameter can parse its own default_string.
#
# This program also verifies that Perl::Critic::EnforcerFactory throws an
# exception when we try to create a enforcer with bogus parameters.  However, it
# is your responsibility to verify that valid parameters actually work as
# expected.  You can do this by using the #parms directive in the *.run files.
#-----------------------------------------------------------------------------

# Figure out how many tests there will be...
my @all_policies = bundled_enforcer_names();
my @all_params   = map { $_->supported_parameters() } @all_policies;
my $ntests       = @all_policies + 2 * @all_params;
plan( tests => $ntests );

#-----------------------------------------------------------------------------

for my $enforcer ( @all_policies ) {
    test_has_declared_parameters( $enforcer );
    test_invalid_parameters( $enforcer );
    test_supported_parameters( $enforcer );
}

#-----------------------------------------------------------------------------

sub test_supported_parameters {
    my $enforcer_name = shift;
    my @supported_params = $enforcer_name->supported_parameters();
    my $config = Perl::Critic::Config->new( -profile => 'NONE' );

    for my $param_specification ( @supported_params ) {
        my $parameter =
            Perl::Critic::EnforcerParameter->new($param_specification);
        my $param_name = $parameter->get_name();
        my $description = $parameter->get_description();

        ok(
            $description && $description ne $NO_DESCRIPTION_AVAILABLE,
            qq{Param "$param_name" for enforcer "$enforcer_name" has a description},
        );

        my %args = (
            -enforcer => $enforcer_name,
            -params => {
                 $param_name => $parameter->get_default_string(),
            }
        );
        eval { $config->add_enforcer( %args ) };
        is(
            $EVAL_ERROR,
            q{},
            qq{Created enforcer "$enforcer_name" with param "$param_name"},
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_invalid_parameters {
    my $enforcer = shift;
    my $bogus_params  = { bogus => 'shizzle' };
    my $profile = Perl::Critic::UserProfile->new( -profile => 'NONE' );
    my $factory = Perl::Critic::EnforcerFactory->new(
        -profile => $profile, '-profile-strictness' => 'fatal' );

    my $enforcer_name = enforcer_short_name($enforcer);
    my $label = qq{Created $enforcer_name with bogus parameters};

    eval { $factory->create_enforcer(-name => $enforcer, -params => $bogus_params) };
    like(
        $EVAL_ERROR,
        qr/The [ ] $enforcer_name [ ] enforcer [ ] doesn't [ ] take [ ] a [ ] "bogus" [ ] option/xms,
        $label
    );

    return;
}

#-----------------------------------------------------------------------------

sub test_has_declared_parameters {
    my $enforcer = shift;
    if ( not $enforcer->can('supported_parameters') ) {
        fail( qq{I don't know if $enforcer supports params} );
        diag( qq{This means $enforcer needs a supported_parameters() method} );
    }
    return;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/14_enforcer_parameters.t_without_optional_dependencies.t
1;

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
