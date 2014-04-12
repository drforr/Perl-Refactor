#!perl

use 5.006001;
use strict;
use warnings;

use Readonly;


use PPI::Document qw< >;
use PPI::Statement::Variable qw< >;
use PPI::Statement qw< >;
use PPI::Token::Word qw< >;

use Perl::Refactor::Utils::Module qw< :all >;

use Test::More tests => 5;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------
#  export tests

can_ok('main', 'get_include_list');

#-----------------------------------------------------------------------------
#  get_include_list tests

ok( ! get_include_list( undef ),
    'get_include_list( undef )',
);

{
    my $doc = PPI::Document->new(\q{use Module::Name 3.14159});
    my @includes = get_include_list( $doc );
    ok $includes[0]->isa('PPI::Statement::Include'),
        q{get_include_list( 'use Module::Name 3.14159' )};
    is $includes[0]->type, 'use';
    is $includes[0]->module, 'Module::Name';
}

## use refactor

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/05_utils_module.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
