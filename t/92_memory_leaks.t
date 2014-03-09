#!perl

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;

use PPI::Document;

use Perl::Refactor::EnforcerFactory -test => 1;
use Perl::Refactor::Document;
use Perl::Refactor;
use Perl::Refactor::TestUtils qw();

use Test::More; #plan set below

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Refactor::TestUtils::block_perlrefactorrc();

eval 'use Test::Memory::Cycle; 1'
    or plan skip_all => 'Test::Memory::Cycle requried to test memory leaks';

#-----------------------------------------------------------------------------
{

    # We have to create and test Perl::Refactor::Document for memory leaks
    # separately because it is not a persistent attribute of the Perl::Refactor
    # object.  The current API requires us to create the P::C::Document from
    # an instance of an existing PPI::Document.  In the future, I hope to make
    # that interface a little more opaque.  But this works for now.

    # Coincidentally, I've discovered that PPI::Documents may or may not
    # contain circular references, depending on the input code.  On some
    # level, I'm sure this makes perfect sense, but I haven't stopped to think
    # about it.  The particular input we use here does not seem to create
    # circular references.

    my $code    = q<print foo(); split /this/, $that;>; ## no refactor (RequireInterpolationOfMetachars)
    my $ppi_doc    = PPI::Document->new( \$code );
    my $pc_doc     = Perl::Refactor::Document->new( '-source' => $ppi_doc );
    my $refactor   = Perl::Refactor->new( -severity => 1 );
    my @violations = $refactor->refactor( $pc_doc );
    confess 'No violations were created' if not @violations;

    # One test for each violation, plus one each for Refactor and Document.
    plan( tests => scalar @violations + 2 );

    memory_cycle_ok( $pc_doc );
    memory_cycle_ok( $refactor );
    foreach my $violation (@violations) {
        memory_cycle_ok($_);
    }
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/92_memory_leaks.t.without_optional_dependencies.t
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
