#!perl

use 5.006001;
use strict;
use warnings;

use Perl::Refactor::Utils qw( :characters );
use Perl::Refactor::TestUtils qw( prefactor );

use Test::More tests => 3;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Refactor::TestUtils::block_perlrefactorrc();

# This specific enforcer is being tested without 20_enforcers.t because the .run file
# would have to contain invisible characters.

my $code;
my $enforcer = 'CodeLayout::ProhibitTrailingWhitespace';

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
say${SPACE}"\tblurp\t";\t
say${SPACE}"${SPACE}blorp${SPACE}";${SPACE}
\f


chomp;\t${SPACE}${SPACE}
chomp;${SPACE}${SPACE}\t
END_PERL

is( prefactor($enforcer, \$code), 5, 'Basic failure' );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
sub${SPACE}do_frobnication${SPACE}\{
\tfor${SPACE}(${SPACE}is_frobnicating()${SPACE})${SPACE}\{
${SPACE}${SPACE}${SPACE}${SPACE}frobnicate();
\l}
}

END_PERL

is( prefactor($enforcer, \$code), 0, 'Basic passing' );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
${SPACE}
${SPACE}\$x
END_PERL

is(
    prefactor($enforcer, \$code),
    1,
    'Multiple lines in a single PPI::Token::Whitespace',
);

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
