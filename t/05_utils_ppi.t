#!perl

use 5.006001;
use strict;
use warnings;

use Readonly;


use PPI::Document qw< >;
use PPI::Statement::Break qw< >;
use PPI::Statement::Compound qw< >;
use PPI::Statement::Data qw< >;
use PPI::Statement::End qw< >;
use PPI::Statement::Expression qw< >;
use PPI::Statement::Include qw< >;
use PPI::Statement::Null qw< >;
use PPI::Statement::Package qw< >;
use PPI::Statement::Scheduled qw< >;
use PPI::Statement::Sub qw< >;
use PPI::Statement::Unknown qw< >;
use PPI::Statement::UnmatchedBrace qw< >;
use PPI::Statement::Variable qw< >;
use PPI::Statement qw< >;
use PPI::Token::Word qw< >;

use Perl::Refactor::Utils::PPI qw< :all >;

use Test::More tests => 80;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

my @ppi_statement_classes = qw{
    PPI::Statement
        PPI::Statement::Package
        PPI::Statement::Include
        PPI::Statement::Sub
            PPI::Statement::Scheduled
        PPI::Statement::Compound
        PPI::Statement::Break
        PPI::Statement::Data
        PPI::Statement::End
        PPI::Statement::Expression
            PPI::Statement::Variable
        PPI::Statement::Null
        PPI::Statement::UnmatchedBrace
        PPI::Statement::Unknown
};

my %instances = map { $_ => $_->new() } @ppi_statement_classes;
$instances{'PPI::Token::Word'} = PPI::Token::Word->new('foo');

#-----------------------------------------------------------------------------
#  export tests

can_ok('main', 'is_ppi_expression_or_generic_statement');
can_ok('main', 'is_ppi_generic_statement');
can_ok('main', 'is_ppi_statement_subclass');
can_ok('main', 'is_subroutine_declaration');
can_ok('main', 'is_in_subroutine');

#-----------------------------------------------------------------------------
#  is_ppi_expression_or_generic_statement tests

{
    ok(
        ! is_ppi_expression_or_generic_statement( undef ),
        'is_ppi_expression_or_generic_statement( undef )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Token::Word'} ),
        'is_ppi_expression_or_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Package'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Include'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Break'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Data'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::End'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::End )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Null'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_ppi_generic_statement tests

{
    ok(
        ! is_ppi_generic_statement( undef ),
        'is_ppi_generic_statement( undef )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Token::Word'} ),
        'is_ppi_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_generic_statement( $instances{'PPI::Statement'} ),
        'is_ppi_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Package'} ),
        'is_ppi_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Include'} ),
        'is_ppi_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Break'} ),
        'is_ppi_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Data'} ),
        'is_ppi_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::End'} ),
        'is_ppi_generic_statement( PPI::Statement::End )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Null'} ),
        'is_ppi_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_generic_statement( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_ppi_statement_subclass tests

{
    ok(
        ! is_ppi_statement_subclass( undef ),
        'is_ppi_statement_subclass( undef )',
    );
    ok(
        ! is_ppi_statement_subclass( $instances{'PPI::Token::Word'} ),
        'is_ppi_statement_subclass( PPI::Token::Word )',
    );
    ok(
        ! is_ppi_statement_subclass( $instances{'PPI::Statement'} ),
        'is_ppi_statement_subclass( PPI::Statement )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Package'} ),
        'is_ppi_statement_subclass( PPI::Statement::Package )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Include'} ),
        'is_ppi_statement_subclass( PPI::Statement::Include )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_statement_subclass( PPI::Statement::Sub )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_statement_subclass( PPI::Statement::Scheduled )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_statement_subclass( PPI::Statement::Compound )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Break'} ),
        'is_ppi_statement_subclass( PPI::Statement::Break )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Data'} ),
        'is_ppi_statement_subclass( PPI::Statement::Data )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::End'} ),
        'is_ppi_statement_subclass( PPI::Statement::End )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_statement_subclass( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_statement_subclass( PPI::Statement::Variable )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Null'} ),
        'is_ppi_statement_subclass( PPI::Statement::Null )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_statement_subclass( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_statement_subclass( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_subroutine_declaration() tests

{
    my $test = sub {
        my ($code, $result) = @_;

        my $doc;
        my $input;

        if (defined $code) {
            $doc = PPI::Document->new(\$code, readonly => 1);
        }
        if (defined $doc) {
            $input = $doc->first_element();
        }

        my $name = defined $code ? $code : '<undef>';

        local $Test::Builder::Level = $Test::Builder::Level + 1; ## no refactor (Variables::ProhibitPackageVars)
        is(
            ! ! is_subroutine_declaration( $input ),
            ! ! $result,
            "is_subroutine_declaration(): $name"
        );

        return;
    };

    $test->('sub {};'        => 1);
    $test->('sub {}'         => 1);
    $test->('{}'             => 0);
    $test->(undef,              0);
    $test->('{ sub foo {} }' => 0);
    $test->('sub foo;'       => 1);
}

#-----------------------------------------------------------------------------
#  is_in_subroutine() tests

{
    my $test = sub {
        my ($code, $transform, $result) = @_;

        my $doc;
        my $input;

        if (defined $code) {
            $doc = PPI::Document->new(\$code, readonly => 1);
        }
        if (defined $doc) {
            $input = $transform->($doc);
        }

        my $name = defined $code ? $code : '<undef>';

        local $Test::Builder::Level = $Test::Builder::Level + 1; ## no refactor (Variables::ProhibitPackageVars)
        is(
            ! ! is_in_subroutine( $input ),
            ! ! $result,
            "is_in_subroutine(): $name"
        );

        return;
    };

    $test->(undef, sub {}, 0);

    ## no refactor (ValuesAndExpressions::RequireInterpolationOfMetachars)
    $test->('my $foo = 42', sub {}, 0);

    $test->(
        'sub foo { my $foo = 42 }',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        1,
    );

    $test->(
        'sub { my $foo = 42 };',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        1,
    );

    $test->(
        '{ my $foo = 42 };',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        0,
    );
    ## use refactor
}

#-----------------------------------------------------------------------------
#

ok !get_flattened_ppi_structure_list(),
    q{get_flattened_ppi_structure_list(): <undef>};

#    ok !get_flattened_ppi_structure_list(
#        PPI::Document->new( \q{no Module::Name} )->child( 0 )
#    ), q{... same with 'no $foo' in general};

#-----------------------------------------------------------------------------
# get_import_list_from_include_statement() tests

ok !get_import_list_from_include_statement( ),
    q{get_import_list_from_include_statement(): <undef>};
ok !get_import_list_from_include_statement( 'foo' ),
    q{get_import_list_from_include_statement( 'foo' )};
ok !get_import_list_from_include_statement(
    PPI::Document->new( \'' )
), q{get_import_list_from_include_statement( PPI::Document )};
ok !get_import_list_from_include_statement(
    PPI::Document->new( \'$a++' )->child( 0 )
), q{get_import_list_from_include_statement( PPI::Statement )};

ok !get_import_list_from_include_statement(
    PPI::Document->new( \q{no strict} )->child( 0 )
), q{get_import_list_from_include_statement( 'no strict' )};

ok !get_import_list_from_include_statement(
    PPI::Document->new( \q{no Module::Name} )->child( 0 )
), q{get_import_list_from_include_statement( 'no Module::Name' )};

ok !get_import_list_from_include_statement(
    PPI::Document->new( \q{require 'Module::Name'} )->child( 0 )
), q{get_import_list_from_include_statement( q{require 'Module::Name'} )};

ok !get_import_list_from_include_statement(
    PPI::Document->new( \q{use 5.006001} )->child( 0 )
), q{get_import_list_from_include_statement( 'use 5.006001' )};

ok !get_import_list_from_include_statement(
    PPI::Document->new( \q{use strict} )->child( 0 )
), q{get_import_list_from_include_statement( 'use strict' )};

ok !get_import_list_from_include_statement(
    PPI::Document->new( \q{use Module::Name} )->child( 0 )
), q{get_import_list_from_include_statement( 'use Module::Name' )};

is_deeply [ get_import_list_from_include_statement(
        PPI::Document->new(\q{use Module::Name 3.14159})->child( 0 )
    ) ],
    [ PPI::Token::Number::Float->new(3.14159) ],
    q{get_import_list_from_include_statement( 'use Module::Name 3.14159' )};

is_deeply [ get_import_list_from_include_statement(
        PPI::Document->new(\q{use Module::Name 'a'})->child( 0 )
    ) ],
    [ PPI::Token::Quote::Single->new(q{'a'}) ],
    q{get_import_list_from_include_statement( q{use Module::Name 'a'} )};

is_deeply [ get_import_list_from_include_statement(
        PPI::Document->new(\q{use Module::Name $variable})->child( 0 )
    ) ],
    [ '$variable' ],
    q{get_import_list_from_include_statement( q{use Module::Name $variable} )};

is_deeply [ get_import_list_from_include_statement(
        PPI::Document->new(
            \q{use Module::Name 'meth_1', 'meth_2'}
        )->child( 0 )
    ) ],
    [ PPI::Token::Quote::Single->new(q{'meth_1'}),
      PPI::Token::Quote::Single->new(q{'meth_2'}) ],
    q{get_import_list_from_include_statement( q{use Module::Name 'meth_1', 'meth_2'} )};

is_deeply [ get_import_list_from_include_statement(
        PPI::Document->new(
            \q{use Module::Name ( 'meth_1', 'meth_2' )}
        )->child( 0 )
    ) ],
    [ PPI::Token::Quote::Single->new(q{'meth_1'}),
      PPI::Token::Quote::Single->new(q{'meth_2'}) ],
    q{get_import_list_from_include_statement( q{use Module::Name ( 'meth_1', 'meth_2' )} )};

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/05_utils_ppi.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
