#!perl

use 5.006001;
use strict;
use warnings;

use Perl::Refactor::UserProfile;
use Perl::Refactor::EnforcerFactory (-test => 1);
use Perl::Refactor::TestUtils qw(bundled_enforcer_names);

use Test::More tests => 1;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Refactor::TestUtils::block_perlrefactorrc();

#-----------------------------------------------------------------------------

my $profile = Perl::Refactor::UserProfile->new();
my $factory = Perl::Refactor::EnforcerFactory->new( -profile => $profile );
my @found_enforcers = sort map { ref $_ } $factory->create_all_enforcers();
my $test_label = 'successfully loaded enforcers matches MANIFEST';
is_deeply( \@found_enforcers, [bundled_enforcer_names()], $test_label );

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/13_bundled_enforcers.t_without_optional_dependencies.t
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
