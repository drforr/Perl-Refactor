#!perl

use 5.006001;
use strict;
use warnings;

use Test::More (tests => 32);
use Perl::Refactor::EnforcerFactory (-test => 1);

# common P::C testing tools
use Perl::Refactor::TestUtils qw(critique);

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Refactor::TestUtils::block_perlrefactorrc();

# Configure Refactor not to load certain policies.  This
# just makes it a little easier to create test cases
my $profile = {
    '-CodeLayout::RequireTidyCode'                               => {},
    '-Documentation::PodSpelling'                                => {},
    '-ErrorHandling::RequireCheckingReturnValueOfEval'           => {},
    '-Miscellanea::ProhibitUnrestrictedNoRefactor'                 => {},
    '-Miscellanea::ProhibitUselessNoRefactor'                      => {},
    '-ValuesAndExpressions::ProhibitMagicNumbers'                => {},
    '-Variables::ProhibitReusedNames'                            => {},
};

my $code = undef;

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

require 'some_library.pl';  ## no refactor
print $crap if $condition;  ## no refactor

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'}
    ),
    0,
    'inline no-refactor disables violations'
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$foo = $bar;

## no refactor

require 'some_library.pl';
print $crap if $condition;

## use refactor

$baz = $nuts;
1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'region no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no refactor
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'scoped no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

{
  ## no refactor
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'scoped no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

## use refactor
my $noisy = '!';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'region no-refactor across a scope',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no refactor
  $long_int = 12345678;
  $oct_num  = 033;
  ## use refactor
}

my $noisy = '!';
my $empty = '';

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    2,
    'scoped region no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'unterminated no-refactor across a scope',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no refactor
$oct_num  = 033;       ## no refactor
my $noisy = '!';       ## no refactor
my $empty = '';        ## no refactor
my $empty = '';        ## use refactor

1;
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'inline use-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no refactor
$oct_num  = 033;       ## no refactor
my $noisy = '!';       ## no refactor
my $empty = '';        ## no refactor

$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    5,
    q<inline no-refactor doesn't block later violations>,
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no refactor
$oct_num  = 033;       ## no refactor
my $noisy = '!';       ## no refactor
my $empty = '';        ## no refactor

## no refactor
$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {
            -profile  => $profile,
            -severity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    9,
    'force option',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no refactor
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!'; ## no refactor
my $empty = '';  ## no refactor

1;
END_PERL

is(
    critique(
        \$code,
        {
            -profile  => $profile,
            -severity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    4,
    'force option',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no refactor
  $long_int = 12345678;
  $oct_num  = 033;
}

## no refactor
my $noisy = '!';
my $empty = '';

#No final '1;'
END_PERL

is(
    critique(
        \$code,
        {
            -profile  => $profile,
            -severity => 1,
            -theme    => 'core',
            -force    => 1,
        }
    ),
    5,
    'force option',
);

#-----------------------------------------------------------------------------
# Check that '## no refactor' on the top of a block doesn't extend
# to all code within the block.  See RT bug #15295

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for ($i;$i++;$i<$j) { ## no refactor
    my $long_int = 12345678;
    my $oct_num  = 033;
}

unless ( $condition1
         && $condition2 ) { ## no refactor
    my $noisy = '!';
    my $empty = '';
}

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    4,
    'RT bug 15295',
);

#-----------------------------------------------------------------------------
# Check that '## no refactor' on the top of a block doesn't extend
# to all code within the block.  See RT bug #15295

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for ($i; $i++; $i<$j) { ## no refactor
    my $long_int = 12345678;
    my $oct_num  = 033;
}

#Between blocks now
$Global::Variable = "foo";  #Package var; double-quotes

unless ( $condition1
         && $condition2 ) { ## no refactor
    my $noisy = '!';
    my $empty = '';
}

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    6,
    'RT bug 15295',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

sub grep {  ## no refactor;
    return $foo;
}

sub grep { return $foo; } ## no refactor
1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'no-refactor on sub name',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

sub grep {  ## no refactor;
   return undef; #Should find this!
}

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity =>1, -theme => 'core'}
    ),
    1,
    'no-refactor on sub name',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (NoisyQuotes)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    2,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (ValuesAndExpressions)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    1,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (Noisy, Empty)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    1,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (NOISY, EMPTY, EVAL)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    0,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (Noisy, Empty, Eval)
my $noisy = '!';
my $empty = '';
eval $string;

## use refactor
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    3,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (Refactor::Enforcer)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    0,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (Foo::Bar, Baz, Boom)
my $noisy = '!';
my $empty = '';
eval $string;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    3,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no refactor (Noisy)
my $noisy = '!';     #Should not find this
my $empty = '';      #Should find this

sub foo {

   ## no refactor (Empty)
   my $nosiy = '!';  #Should not find this
   my $empty = '';   #Should not find this
   ## use refactor;

   return 1;
}

my $nosiy = '!';  #Should not find this
my $empty = '';   #Should find this

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'}
    ),
    2,
    'per-enforcer no-refactor',
);

#-----------------------------------------------------------------------------
$code = <<'END_PERL';
package FOO;

use strict;
use warnings;
our $VERSION = 1.0;

# with parentheses
my $noisy = '!';           ##no refactor (NoisyQuotes)
barf() unless $$ eq '';    ##no refactor (Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no refactor (Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##no refactor (Postfix Empty Punctuation)

# qw() style
my $noisy = '!';           ##no refactor qw(NoisyQuotes);
barf() unless $$ eq '';    ##no refactor qw(Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no refactor qw(Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##no refactor qw(Postfix Empty Punctuation)

# with quotes
my $noisy = '!';           ##no refactor 'NoisyQuotes';
barf() unless $$ eq '';    ##no refactor 'Postfix,Empty,Punctuation';
barf() unless $$ eq '';    ##no refactor 'Postfix , Empty , Punctuation';
barf() unless $$ eq '';    ##no refactor 'Postfix Empty Punctuation';

# with double quotes
my $noisy = '!';           ##no refactor "NoisyQuotes";
barf() unless $$ eq '';    ##no refactor "Postfix,Empty,Punctuation";
barf() unless $$ eq '';    ##no refactor "Postfix , Empty , Punctuation";
barf() unless $$ eq '';    ##no refactor "Postfix Empty Punctuation";

# with spacing variations
my $noisy = '!';           ##no refactor (NoisyQuotes)
barf() unless $$ eq '';    ##  no   refactor   (Postfix,Empty,Punctuation)
barf() unless $$ eq '';    ##no refactor(Postfix , Empty , Punctuation)
barf() unless $$ eq '';    ##   no refactor(Postfix Empty Punctuation)

1;

END_PERL

is(
    critique(
        \$code,
        {-profile => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'no refactor: syntaxes',
);

#-----------------------------------------------------------------------------
# Most policies apply to a particular type of PPI::Element and usually
# only return one Violation at a time.  But the next three cases
# involve policies that apply to the whole document and can return
# multiple violations at a time.  These tests make sure that the 'no
# refactor' pragmas are effective with those Enforcers
#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;

#Code before 'use strict'
my $foo = 'baz';  ## no refactor
my $bar = 42;     # Should find this

use strict;
use warnings;
our $VERSION = 1.0;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 5, -theme => 'core'},
    ),
    1,
    'no refactor & RequireUseStrict',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;

#Code before 'use warnings'
my $foo = 'baz';  ## no refactor
my $bar = 42;  # Should find this

use warnings;
our $VERSION = 1.0;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 4, -theme => 'core'},
    ),
    1,
    'no refactor & RequireUseWarnings',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use strict;      ##no refactor
use warnings;    #should find this
my $bar = 42;    #this one will be squelched

package FOO;

our $VERSION = 1.0;

1;
END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 4, -theme => 'core'},
    ),
    1,
    'no refactor & RequireExplicitPackage',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl -w ## no refactor

package Foo;
use strict;
use warnings;
our $VERSION = 1;

my $noisy = '!'; # should find this

END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    1,
    'no-refactor on shebang line'
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#line 1
## no refactor;

=pod

=head1 SOME POD HERE

This code has several POD-related violations at line 1.  The "## no refactor"
marker is on the second physical line.  However, the "#line" directive should
cause it to treat it as if it actually were on the first physical line.  Thus,
the violations should be supressed.

=cut

END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'no-refactor where logical line == 1, but physical line != 1'
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#line 7
## no refactor;

=pod

=head1 SOME POD HERE

This code has several POD-related violations at line 1.  The "## no refactor"
marker is on the second physical line, and the "#line" directive should cause
it to treat it as if it actually were on the 7th physical line.  Thus, the
violations should NOT be supressed.

=cut

END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    2,
    'no-refactor at logical line != 1, and physical line != 1'
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#line 1
#!perl ### no refactor;

package Foo;
use strict;
use warnings;
our $VERSION = 1;

# In this case, the "## no refactor" marker is on the first logical line, which
# is also the shebang line.

1;

END_PERL

is(
    critique(
        \$code,
        {-profile  => $profile, -severity => 1, -theme => 'core'},
    ),
    0,
    'no-refactor on shebang line, where physical line != 1, but logical line == 1'
);

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/03_pragmas.t_without_optional_dependencies.t
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
