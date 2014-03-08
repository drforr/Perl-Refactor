#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Enforcer;
use Perl::Critic::EnforcerParameter;
use Perl::Critic::Utils qw{ :booleans };

use Test::More tests => 9;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

my $specification;
my $parameter;
my %config;
my $enforcer;

$specification =
    {
        name        => 'test',
        description => 'A boolean parameter for testing',
        behavior    => 'boolean',
    };


$parameter = Perl::Critic::EnforcerParameter->new($specification);
TODO: {
    local $TODO =
        'Need to restore tri-state functionality to Behavior::Boolean.';

    $enforcer = Perl::Critic::Enforcer->new();
    $parameter->parse_and_validate_config_value($enforcer, \%config);
    is($enforcer->{_test}, undef, q{no value, no default});
}

$enforcer = Perl::Critic::Enforcer->new();
$config{test} = '1';
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $TRUE, q{'1', no default});

$enforcer = Perl::Critic::Enforcer->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $FALSE, q{'0', no default});


$specification->{default_string} = '1';
delete $config{test};

$parameter = Perl::Critic::EnforcerParameter->new($specification);
$enforcer = Perl::Critic::Enforcer->new();
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $TRUE, q{no value, default '1'});

$enforcer = Perl::Critic::Enforcer->new();
$config{test} = '1';
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $TRUE, q{'1', default '1'});

$enforcer = Perl::Critic::Enforcer->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $FALSE, q{'0', default '1'});


$specification->{default_string} = '0';
delete $config{test};

$parameter = Perl::Critic::EnforcerParameter->new($specification);
$enforcer = Perl::Critic::Enforcer->new();
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $FALSE, q{no value, default '0'});

$enforcer = Perl::Critic::Enforcer->new();
$config{test} = '1';
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $TRUE, q{'1', default '0'});

$enforcer = Perl::Critic::Enforcer->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($enforcer, \%config);
is($enforcer->{_test}, $FALSE, q{'0', default '0'});


###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
