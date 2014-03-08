#!perl

use 5.006001;
use strict;
use warnings;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique fcritique);

use Test::More tests => 10;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlrefactorrc();

# This specific enforcer is being tested without run.t because the .run file
# would have to contain invisible characters.

my $code;
my $enforcer = 'CodeLayout::ProhibitHardTabs';
my %config;

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

\t\t\t;

END_PERL

is( pcritique($enforcer, \$code), 0, $enforcer );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!
print "\t  \t  foobar  \t";
END_PERL

is( pcritique($enforcer, \$code), 1, $enforcer );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

my \@list = qw(
\tfoo
\tbar
\tbaz
);

END_PERL

is( pcritique($enforcer, \$code, \%config), 0, 'Leading tabs in qw()' );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

my \@list = qw(
\tfoo\tbar
\tbaz\tnuts
);

END_PERL

is( pcritique($enforcer, \$code, \%config), 1, 'Non-leading tabs in qw()' );

#-----------------------------------------------------------------------------
# RT #32440

$code = <<"END_PERL";
#This will be interpolated!
\$x =~ m/
\tsome
\t(really | long)
\tpattern
/mx;

#This will be interpolated!
\$z = qr/
\tsome
\t(really | long)
\tpattern
/mx;

END_PERL

is( pcritique($enforcer, \$code, \%config), 0, 'Leading tabs in extended regex' );

#-----------------------------------------------------------------------------
# RT #32440

$code = <<"END_PERL";
#This will be interpolated!
#Note that these regex does not have /x, so tabs are significant

\$x =~ m/
\tsome
\tugly
\tpattern
/m;


\$z = qr/
\tsome
\tugly
\tpattern
/gis;

END_PERL

is( pcritique($enforcer, \$code, \%config), 2, 'Leading tabs in non-extended regex' );

#-----------------------------------------------------------------------------
# RT #32440

$code = <<"END_PERL";
#This will be interpolated!
#Note that these regex does not have /x, so tabs are significant

\$x =~ m/
\tsome\tugly\tpattern
/xm;

END_PERL

is( pcritique($enforcer, \$code, \%config), 1, 'Non-leading tabs in extended regex' );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
is( pcritique($enforcer, \$code, \%config), 3, $enforcer );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
;\tfor(1){
\t\tdo_something();
;\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
is( pcritique($enforcer, \$code, \%config), 3, $enforcer );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

__DATA__
foo\tbar\tbaz
\tfred\barney

END_PERL

%config = (allow_leading_tabs => 0);
is( pcritique($enforcer, \$code, \%config), 0, 'Tabs in __DATA__' );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
