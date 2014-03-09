#!perl

use 5.006001;
use strict;
use warnings;

use English qw<-no_match_vars>;

use Perl::Refactor::UserProfile;
use Perl::Refactor::EnforcerFactory (-test => 1);
use Perl::Refactor::ThemeListing;

use Test::More tests => 1;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

my $profile = Perl::Refactor::UserProfile->new( -profile => 'NONE' );
my @enforcer_names = Perl::Refactor::EnforcerFactory::site_enforcer_names();
my $factory = Perl::Refactor::EnforcerFactory->new( -profile => $profile );
my @enforcers = map { $factory->create_enforcer( -name => $_ ) } @enforcer_names;
my $listing = Perl::Refactor::ThemeListing->new( -enforcers => \@enforcers );

my $expected = <<'END_EXPECTED';
bugs
certrec
certrule
complexity
core
cosmetic
maintenance
pbp
performance
portability
readability
security
tests
unicode
END_EXPECTED

my $listing_as_string = "$listing";
is( $listing_as_string, $expected, 'Theme list matched.' );

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/12_themelisting.t_without_optional_dependencies.t
1;

#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
