#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Refactor::UserProfile;
use Perl::Refactor::EnforcerFactory (-test => 1);
use Perl::Refactor::TestUtils qw();

use Test::More tests => 10;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Refactor::TestUtils::block_perlrefactorrc();

#-----------------------------------------------------------------------------

{
    my $enforcer_name = 'Perl::Refactor::Enforcer::Modules::ProhibitEvilModules';
    my $params = {severity => 2, set_themes => 'betty', add_themes => 'wilma'};

    my $userprof = Perl::Refactor::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::Refactor::EnforcerFactory->new( -profile  => $userprof );


    # Now test...
    my $enforcer = $pf->create_enforcer( -name => $enforcer_name, -params => $params );
    is( ref $enforcer, $enforcer_name, 'Created correct type of enforcer');

    my $severity = $enforcer->get_severity();
    is( $severity, 2, 'Set the severity');

    my @themes = $enforcer->get_themes();
    is_deeply( \@themes, [ qw(betty wilma) ], 'Set the theme');
}

#-----------------------------------------------------------------------------
# Using short module name.
{
    my $enforcer_name = 'Variables::ProhibitPunctuationVars';
    my $params = {set_themes => 'betty', add_themes => 'wilma'};

    my $userprof = Perl::Refactor::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::Refactor::EnforcerFactory->new( -profile  => $userprof );


    # Now test...
    my $enforcer = $pf->create_enforcer( -name => $enforcer_name, -params => $params );
    my $enforcer_name_long = 'Perl::Refactor::Enforcer::' . $enforcer_name;
    is( ref $enforcer, $enforcer_name_long, 'Created correct type of enforcer');

    my @themes = $enforcer->get_themes();
    is_deeply( \@themes, [ qw(betty wilma) ], 'Set the theme');
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $userprof = Perl::Refactor::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::Refactor::EnforcerFactory->new( -profile  => $userprof );

    # Try missing arguments
    eval{ $pf->create_enforcer() };
    like(
        $EVAL_ERROR,
        qr/The [ ] -name [ ] argument/xms,
        'create without -name arg',
    );

    # Try creating bogus enforcer
    eval{ $pf->create_enforcer( -name => 'Perl::Refactor::Foo' ) };
    like(
        $EVAL_ERROR,
        qr/Can't [ ] locate [ ] object [ ] method/xms,
        'create bogus enforcer',
    );

    # Try using a bogus severity level
    my $enforcer_name = 'Modules::RequireVersionVar';
    my $enforcer_params = {severity => 'bogus'};
    eval{ $pf->create_enforcer( -name => $enforcer_name, -params => $enforcer_params)};
    like(
        $EVAL_ERROR,
        qr/Invalid [ ] severity: [ ] "bogus"/xms,
        'create enforcer w/ bogus severity',
    );
}

#-----------------------------------------------------------------------------
# Test warnings about bogus policies

{
    my $last_warning = q{}; #Trap warning messages here
    local $SIG{__WARN__} = sub { $last_warning = shift };

    my $profile = { 'Perl::Refactor::Bogus' => {} };
    my $userprof = Perl::Refactor::UserProfile->new( -profile => $profile );
    my $pf = Perl::Refactor::EnforcerFactory->new( -profile  => $userprof );
    like(
        $last_warning,
        qr/^Enforcer [ ] ".*Bogus" [ ] is [ ] not [ ] installed/xms,
        'Got expected warning for positive configuration of Enforcer.',
    );
    $last_warning = q{};

    $profile = { '-Perl::Refactor::Shizzle' => {} };
    $userprof = Perl::Refactor::UserProfile->new( -profile => $profile );
    $pf = Perl::Refactor::EnforcerFactory->new( -profile  => $userprof );
    like(
        $last_warning,
        qr/^Enforcer [ ] ".*Shizzle" [ ] is [ ] not [ ] installed/xms,
        'Got expected warning for negative configuration of Enforcer.',
    );
    $last_warning = q{};
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/11_enforcerfactory.t_without_optional_dependencies.t
1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
