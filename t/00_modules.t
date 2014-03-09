#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use PPI::Document;

use Perl::Refactor::TestUtils qw(bundled_enforcer_names);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Refactor::TestUtils::block_perlrefactorrc();

my @bundled_enforcer_names = bundled_enforcer_names();

my @concrete_exceptions = qw{
    AggregateConfiguration
    Configuration::Generic
    Configuration::NonExistentEnforcer
    Configuration::Option::Global::ExtraParameter
    Configuration::Option::Global::ParameterValue
    Configuration::Option::Enforcer::ExtraParameter
    Configuration::Option::Enforcer::ParameterValue
    Fatal::Generic
    Fatal::Internal
    Fatal::EnforcerDefinition
    IO
};

plan tests =>
        144
    +   (  9 * scalar @concrete_exceptions  )
    +   ( 17 * scalar @bundled_enforcer_names );

# pre-compute for version comparisons
my $version_string = __PACKAGE__->VERSION;

#-----------------------------------------------------------------------------
# Test Perl::Refactor module interface

use_ok('Perl::Refactor') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor', 'new');
can_ok('Perl::Refactor', 'add_enforcer');
can_ok('Perl::Refactor', 'config');
can_ok('Perl::Refactor', 'refactor');
can_ok('Perl::Refactor', 'enforcers');

#Set -profile to avoid messing with .perlrefactorrc
my $refactor = Perl::Refactor->new( -profile => 'NONE' );
isa_ok($refactor, 'Perl::Refactor');
is($refactor->VERSION(), $version_string, 'Perl::Refactor version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::Config module interface

use_ok('Perl::Refactor::Config') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::Config', 'new');
can_ok('Perl::Refactor::Config', 'add_enforcer');
can_ok('Perl::Refactor::Config', 'enforcers');
can_ok('Perl::Refactor::Config', 'exclude');
can_ok('Perl::Refactor::Config', 'force');
can_ok('Perl::Refactor::Config', 'include');
can_ok('Perl::Refactor::Config', 'only');
can_ok('Perl::Refactor::Config', 'profile_strictness');
can_ok('Perl::Refactor::Config', 'severity');
can_ok('Perl::Refactor::Config', 'single_enforcer');
can_ok('Perl::Refactor::Config', 'theme');
can_ok('Perl::Refactor::Config', 'top');
can_ok('Perl::Refactor::Config', 'verbose');
can_ok('Perl::Refactor::Config', 'color');
can_ok('Perl::Refactor::Config', 'unsafe_allowed');
can_ok('Perl::Refactor::Config', 'criticism_fatal');
can_ok('Perl::Refactor::Config', 'site_enforcer_names');
can_ok('Perl::Refactor::Config', 'color_severity_highest');
can_ok('Perl::Refactor::Config', 'color_severity_high');
can_ok('Perl::Refactor::Config', 'color_severity_medium');
can_ok('Perl::Refactor::Config', 'color_severity_low');
can_ok('Perl::Refactor::Config', 'color_severity_lowest');
can_ok('Perl::Refactor::Config', 'program_extensions');
can_ok('Perl::Refactor::Config', 'program_extensions_as_regexes');

#Set -profile to avoid messing with .perlrefactorrc
my $config = Perl::Refactor::Config->new( -profile => 'NONE');
isa_ok($config, 'Perl::Refactor::Config');
is($config->VERSION(), $version_string, 'Perl::Refactor::Config version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::Config::OptionsProcessor module interface

use_ok('Perl::Refactor::OptionsProcessor') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::OptionsProcessor', 'new');
can_ok('Perl::Refactor::OptionsProcessor', 'exclude');
can_ok('Perl::Refactor::OptionsProcessor', 'include');
can_ok('Perl::Refactor::OptionsProcessor', 'force');
can_ok('Perl::Refactor::OptionsProcessor', 'only');
can_ok('Perl::Refactor::OptionsProcessor', 'profile_strictness');
can_ok('Perl::Refactor::OptionsProcessor', 'single_enforcer');
can_ok('Perl::Refactor::OptionsProcessor', 'severity');
can_ok('Perl::Refactor::OptionsProcessor', 'theme');
can_ok('Perl::Refactor::OptionsProcessor', 'top');
can_ok('Perl::Refactor::OptionsProcessor', 'verbose');
can_ok('Perl::Refactor::OptionsProcessor', 'color');
can_ok('Perl::Refactor::OptionsProcessor', 'allow_unsafe');
can_ok('Perl::Refactor::OptionsProcessor', 'criticism_fatal');
can_ok('Perl::Refactor::OptionsProcessor', 'color_severity_highest');
can_ok('Perl::Refactor::OptionsProcessor', 'color_severity_high');
can_ok('Perl::Refactor::OptionsProcessor', 'color_severity_medium');
can_ok('Perl::Refactor::OptionsProcessor', 'color_severity_low');
can_ok('Perl::Refactor::OptionsProcessor', 'color_severity_lowest');
can_ok('Perl::Refactor::OptionsProcessor', 'program_extensions');

my $processor = Perl::Refactor::OptionsProcessor->new();
isa_ok($processor, 'Perl::Refactor::OptionsProcessor');
is($processor->VERSION(), $version_string, 'Perl::Refactor::OptionsProcessor version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::Enforcer module interface

use_ok('Perl::Refactor::Enforcer') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::Enforcer', 'add_themes');
can_ok('Perl::Refactor::Enforcer', 'applies_to');
can_ok('Perl::Refactor::Enforcer', 'default_maximum_violations_per_document');
can_ok('Perl::Refactor::Enforcer', 'default_severity');
can_ok('Perl::Refactor::Enforcer', 'default_themes');
can_ok('Perl::Refactor::Enforcer', 'get_abstract');
can_ok('Perl::Refactor::Enforcer', 'get_format');
can_ok('Perl::Refactor::Enforcer', 'get_long_name');
can_ok('Perl::Refactor::Enforcer', 'get_maximum_violations_per_document');
can_ok('Perl::Refactor::Enforcer', 'get_parameters');
can_ok('Perl::Refactor::Enforcer', 'get_raw_abstract');
can_ok('Perl::Refactor::Enforcer', 'get_severity');
can_ok('Perl::Refactor::Enforcer', 'get_short_name');
can_ok('Perl::Refactor::Enforcer', 'get_themes');
can_ok('Perl::Refactor::Enforcer', 'initialize_if_enabled');
can_ok('Perl::Refactor::Enforcer', 'is_enabled');
can_ok('Perl::Refactor::Enforcer', 'is_safe');
can_ok('Perl::Refactor::Enforcer', 'new');
can_ok('Perl::Refactor::Enforcer', 'new_parameter_value_exception');
can_ok('Perl::Refactor::Enforcer', 'parameter_metadata_available');
can_ok('Perl::Refactor::Enforcer', 'prepare_to_scan_document');
can_ok('Perl::Refactor::Enforcer', 'set_format');
can_ok('Perl::Refactor::Enforcer', 'set_maximum_violations_per_document');
can_ok('Perl::Refactor::Enforcer', 'set_severity');
can_ok('Perl::Refactor::Enforcer', 'set_themes');
can_ok('Perl::Refactor::Enforcer', 'throw_parameter_value_exception');
can_ok('Perl::Refactor::Enforcer', 'to_string');
can_ok('Perl::Refactor::Enforcer', 'violates');
can_ok('Perl::Refactor::Enforcer', 'violation');
can_ok('Perl::Refactor::Enforcer', 'is_safe');

{
    my $enforcer = Perl::Refactor::Enforcer->new();
    isa_ok($enforcer, 'Perl::Refactor::Enforcer');
    is($enforcer->VERSION(), $version_string, 'Perl::Refactor::Enforcer version');
}

#-----------------------------------------------------------------------------
# Test Perl::Refactor::Violation module interface

use_ok('Perl::Refactor::Violation') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::Violation', 'description');
can_ok('Perl::Refactor::Violation', 'diagnostics');
can_ok('Perl::Refactor::Violation', 'explanation');
can_ok('Perl::Refactor::Violation', 'get_format');
can_ok('Perl::Refactor::Violation', 'location');
can_ok('Perl::Refactor::Violation', 'new');
can_ok('Perl::Refactor::Violation', 'enforcer');
can_ok('Perl::Refactor::Violation', 'set_format');
can_ok('Perl::Refactor::Violation', 'severity');
can_ok('Perl::Refactor::Violation', 'sort_by_location');
can_ok('Perl::Refactor::Violation', 'sort_by_severity');
can_ok('Perl::Refactor::Violation', 'source');
can_ok('Perl::Refactor::Violation', 'to_string');

my $code = q{print 'Hello World';};
my $doc = PPI::Document->new(\$code);
my $viol = Perl::Refactor::Violation->new(undef, undef, $doc, undef);
isa_ok($viol, 'Perl::Refactor::Violation');
is($viol->VERSION(), $version_string, 'Perl::Refactor::Violation version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::UserProfile module interface

use_ok('Perl::Refactor::UserProfile') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::UserProfile', 'options_processor');
can_ok('Perl::Refactor::UserProfile', 'new');
can_ok('Perl::Refactor::UserProfile', 'enforcer_is_disabled');
can_ok('Perl::Refactor::UserProfile', 'enforcer_is_enabled');

my $up = Perl::Refactor::UserProfile->new();
isa_ok($up, 'Perl::Refactor::UserProfile');
is($up->VERSION(), $version_string, 'Perl::Refactor::UserProfile version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::EnforcerFactory module interface

use_ok('Perl::Refactor::EnforcerFactory') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::EnforcerFactory', 'create_enforcer');
can_ok('Perl::Refactor::EnforcerFactory', 'new');
can_ok('Perl::Refactor::EnforcerFactory', 'site_enforcer_names');


my $profile = Perl::Refactor::UserProfile->new();
my $factory = Perl::Refactor::EnforcerFactory->new( -profile => $profile );
isa_ok($factory, 'Perl::Refactor::EnforcerFactory');
is($factory->VERSION(), $version_string, 'Perl::Refactor::EnforcerFactory version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::Theme module interface

use_ok('Perl::Refactor::Theme') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::Theme', 'new');
can_ok('Perl::Refactor::Theme', 'rule');
can_ok('Perl::Refactor::Theme', 'enforcer_is_thematic');


my $theme = Perl::Refactor::Theme->new( -rule => 'foo' );
isa_ok($theme, 'Perl::Refactor::Theme');
is($theme->VERSION(), $version_string, 'Perl::Refactor::Theme version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::EnforcerListing module interface

use_ok('Perl::Refactor::EnforcerListing') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::EnforcerListing', 'new');
can_ok('Perl::Refactor::EnforcerListing', 'to_string');

my $listing = Perl::Refactor::EnforcerListing->new();
isa_ok($listing, 'Perl::Refactor::EnforcerListing');
is($listing->VERSION(), $version_string, 'Perl::Refactor::EnforcerListing version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::ProfilePrototype module interface

use_ok('Perl::Refactor::ProfilePrototype') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::ProfilePrototype', 'new');
can_ok('Perl::Refactor::ProfilePrototype', 'to_string');

my $prototype = Perl::Refactor::ProfilePrototype->new();
isa_ok($prototype, 'Perl::Refactor::ProfilePrototype');
is($prototype->VERSION(), $version_string, 'Perl::Refactor::ProfilePrototype version');

#-----------------------------------------------------------------------------
# Test Perl::Refactor::Command module interface

use_ok('Perl::Refactor::Command') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Refactor::Command', 'run');

#-----------------------------------------------------------------------------
# Test module interface for exceptions

{
    foreach my $class (
        map { "Perl::Refactor::Exception::$_" } @concrete_exceptions
    ) {
        use_ok($class) or BAIL_OUT(q<Can't continue.>);
        can_ok($class, 'new');
        can_ok($class, 'throw');
        can_ok($class, 'message');
        can_ok($class, 'error');
        can_ok($class, 'full_message');
        can_ok($class, 'as_string');

        my $exception = $class->new();
        isa_ok($exception, $class);
        is($exception->VERSION(), $version_string, "$class version");
    }
}

#-----------------------------------------------------------------------------
# Test module interface for each Enforcer subclass

{
    for my $mod ( @bundled_enforcer_names ) {

        use_ok($mod) or BAIL_OUT(q<Can't continue.>);
        can_ok($mod, 'applies_to');
        can_ok($mod, 'default_severity');
        can_ok($mod, 'default_themes');
        can_ok($mod, 'get_severity');
        can_ok($mod, 'get_themes');
        can_ok($mod, 'is_enabled');
        can_ok($mod, 'new');
        can_ok($mod, 'set_severity');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'violates');
        can_ok($mod, 'violation');
        can_ok($mod, 'is_safe');

        my $enforcer = $mod->new();
        isa_ok($enforcer, 'Perl::Refactor::Enforcer');
        is($enforcer->VERSION(), $version_string, "Version of $mod");
        ok($enforcer->is_safe(), "CORE enforcer $mod is marked safe");
    }
}

#-----------------------------------------------------------------------------
# Test functional interface to Perl::Refactor

Perl::Refactor->import( qw(refactor) );
can_ok('main', 'refactor');  #Export test

# TODO: These tests are weak. They just verify that it doesn't
# blow up, and that at least one violation is returned.
ok( refactor( \$code ), 'Functional style, no config' );
ok( refactor( {}, \$code ), 'Functional style, empty config' );
ok( refactor( {severity => 1}, \$code ), 'Functional style, with config');
ok( !refactor(), 'Functional style, no args at all');
ok( !refactor(undef, undef), 'Functional style, undef args');

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/00_modules.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
