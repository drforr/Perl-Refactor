#!perl

# Self-compliance tests

use 5.006001;
use strict;
use warnings;

use English qw( -no_match_vars );

use File::Spec qw();

use Perl::Refactor::Utils qw{ :characters };
use Perl::Refactor::TestUtils qw{ starting_points_including_examples };

# Note: "use EnforcerFactory" *must* appear after "use TestUtils" for the
# -extra-test-policies option to work.
use Perl::Refactor::EnforcerFactory (
    '-test' => 1,
    '-extra-test-policies' => [ qw{ ErrorHandling::RequireUseOfExceptions
                                    Miscellanea::RequireRcsKeywords } ],
);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

use Test::Perl::Refactor;

#-----------------------------------------------------------------------------

# Fall over if P::C::More isn't installed.
use Perl::Refactor::Enforcer::ErrorHandling::RequireUseOfExceptions;

#-----------------------------------------------------------------------------
# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_CRITIC_CACHE} ) {
    require PPI::Cache;
    my $cache_path =
        File::Spec->catdir(
            File::Spec->tmpdir,
            "test-perl-refactor-cache-$ENV{USER}",
        );
    if ( ! -d $cache_path) {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import( path => $cache_path );
}

#-----------------------------------------------------------------------------
# Strict object testing -- prevent direct hash key access

use Devel::EnforceEncapsulation;
foreach my $pkg ( $EMPTY, qw< ::Config ::Enforcer ::Violation> ) {
    Devel::EnforceEncapsulation->apply_to('Perl::Refactor'.$pkg);
}

#-----------------------------------------------------------------------------
# Run refactor against all of our own files

my $rcfile = File::Spec->catfile( 'xt', 'author', '40_perlrefactorrc-code' );
Test::Perl::Refactor->import( -profile => $rcfile );

all_refactor_ok( starting_points_including_examples() );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
