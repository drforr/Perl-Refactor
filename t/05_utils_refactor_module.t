#!perl

use 5.006001;
use strict;
use warnings;

use Readonly;

use PPI::Document qw< >;

use Perl::Refactor::Utils::Refactor::Module qw< :all >;

use Test::More tests => 14;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------
#  export tests

can_ok('main', 'enforce_module_bases');
can_ok('main', 'enforce_module_imports');

#-----------------------------------------------------------------------------
#  enforce_module_imports tests

Readonly my $DEFAULT_CONFIGURATION => {
    aggression => 0
};

sub _enforce_base {
    my ( $expression, @base ) = @_;
    my $configuration = $DEFAULT_CONFIGURATION;
    if ( ref( $expression ) ) {
        $configuration = $expression;
        $expression = shift @base;
    }
    my $element = PPI::Document->new( \$expression );
    my $child = $element->child( 0 );
    my $enforced = enforce_module_bases( $configuration, $child, @base );
    return ref( $enforced ) ? $enforced->content : $enforced;
}

sub _enforce {
    my ( $expression, @import ) = @_;
    my $configuration = $DEFAULT_CONFIGURATION;
    if ( ref( $expression ) ) {
        $configuration = $expression;
        $expression = shift @import;
    }
    my $element = PPI::Document->new( \$expression );
    my $child = $element->child( 0 );
    my $enforced = enforce_module_imports( $configuration, $child, @import );
    return ref( $enforced ) ? $enforced->content : $enforced;
}

subtest 'returns undef on bad/missing input' => sub {

    ok( ! enforce_module_imports( undef ),
        q{returns with no args}
    );

    ok( ! enforce_module_imports( 'any' ),
        q{... or a single scalar}
    );

    ok( ! enforce_module_imports( $DEFAULT_CONFIGURATION ),
        q{... or a single hashref}
    );

    ok( ! enforce_module_imports( $DEFAULT_CONFIGURATION,
            PPI::Document->new(\q{}) ),
        q{... Or a hashref and document}
    );

    ok( ! enforce_module_imports( $DEFAULT_CONFIGURATION,
            PPI::Document->new(\q{}), undef ),
        q{... or a hashref, document and no added imports}
    );
};

subtest 'add existing import' => sub {

    is _enforce( q{use Module::Name 'any'}, 'any' ),
        q{use Module::Name 'any'},
        q{Adding an existing import shouldn't change anything};

    subtest '... run through the q{} variants' => sub {

        is _enforce( q{use Module::Name q{any}}, 'any' ),
            q{use Module::Name q{any}},
            q{using q{} shouldn't matter};

        is _enforce( q{use Module::Name qq{any}}, 'any' ),
            q{use Module::Name qq{any}},
            q{using qq{} shouldn't matter};

        is _enforce( q{use Module::Name "any"}, 'any' ),
            q{use Module::Name "any"},
            q{using "" shouldn't matter};
    };

    is _enforce( q{use Module::Name 'first', 'any'}, 'any' ),
        q{use Module::Name 'first', 'any'},
        q{... even if there are multiple imports};

    is _enforce( q{use Module::Name 'any', 'last'}, 'any' ),
        q{use Module::Name 'any', 'last'},
        q{... no matter what order they appear in};

    is _enforce( q{use Module::Name ( 'any' )}, 'any' ),
        q{use Module::Name ( 'any' )},
        q{... or in a list};

    is _enforce( q{use Module::Name (( 'any' ))}, 'any' ),
        q{use Module::Name (( 'any' ))},
        q{... no matter how deeply nested};

    is _enforce( q{use Module::Name [ 'any' ]}, 'any' ),
        q{use Module::Name [ 'any' ], qw< any >},
        q{... [] references are a different matter};
};

subtest 'add new import conservatively' => sub {

    is _enforce( q{use Module::Name}, 'any' ),
        q{use Module::Name qw< any >},
        q{imports get added with qw<>};

    is _enforce( q{use Module::Name 'croak'}, 'any' ),
        q{use Module::Name 'croak', qw< any >},
        q{... after the last import term};

    is _enforce( q{use Module::Name qw( )}, 'any' ),
        q{use Module::Name qw( ), qw< any >},
        q{... Or after a qw( )};

    is _enforce( q{use Module::Name qw( croak )}, 'any' ),
        q{use Module::Name qw( croak ), qw< any >},
        q{... Or after a qw( foo )};

    is _enforce( q{use Module::Name ( )}, 'any' ),
        q{use Module::Name ( ), qw< any >},
        q{... Or after a ( )};

    is _enforce( q{use Module::Name ( 'croak' )}, 'any' ),
        q{use Module::Name ( 'croak' ), qw< any >},
        q{... Or after a ( 'foo' )};

    is _enforce( q{use Module::Name [ ]}, 'any' ),
        q{use Module::Name [ ], qw< any >},
        q{... or [ ]};

    is _enforce( q{use Module::Name [ 'croak' ]}, 'any' ),
        q{use Module::Name [ 'croak' ], qw< any >},
        q{... or [ 'foo' ]};

    is _enforce( q{use Module::Name { }}, 'any' ),
        q{use Module::Name { }, qw< any >},
        q{... or { }};

    is _enforce( q{use Module::Name { croak => 1 }}, 'any' ),
        q{use Module::Name { croak => 1 }, qw< any >},
        q{... or { foo => 1 }};

    is _enforce( q{use Module::Name 'croak', 'carp'}, 'any' ),
        q{use Module::Name 'croak', 'carp', qw< any >},
        q{... Or after multiple 'foo'};

    is _enforce( q{use Module::Name 'croak',}, 'any' ),
        q{use Module::Name 'croak', qw< any >},
        q{... Trailing commas don't get duplicated};

    is _enforce( q{use Module::Name 'croak' =>}, 'any' ),
        q{use Module::Name 'croak' => qw< any >},
        q{... Fat commas count as regular commas};

    is _enforce( q{use Module::Name croak =>}, 'any' ),
        q{use Module::Name croak => qw< any >},
        q{... and quotes don't matter};

    is _enforce( q{use Module::Name 'croak' => 'yes'}, 'any' ),
        q{use Module::Name 'croak' => 'yes', qw< any >},
        q{... even if there's a term after};

    subtest "don't look inside references for import names though" => sub {

        is _enforce( q{use Module::Name [ 'any' ]}, 'any' ),
            q{use Module::Name [ 'any' ], qw< any >},
            q{... ['foo'] and 'foo' are different};

        is _enforce( q{use Module::Name { any => 1 }}, 'any' ),
            q{use Module::Name { any => 1 }, qw< any >},
            q{... {'any' => 1} and 'any' are different};
    };
};

subtest 'module floating-point versions preserve space' => sub {

    is _enforce( q{use Module::Name -5.003}, 'any' ),
        q{use Module::Name -5.003 qw< any >},
        q{Versions don't need commas};

    is _enforce( q{use Module::Name 5.003}, 'any' ),
        q{use Module::Name 5.003 qw< any >},
        q{Versions don't need commas};

    is _enforce( q{use Module::Name '5.003'}, 'any' ),
        q{use Module::Name '5.003' qw< any >},
        q{... And of course even in quotes they don't need them};

=pod
    is _enforce( q{use Module::Name 5.003 -bareword}, 'any' ),
        q{use Module::Name 5.003 -bareword, qw< any >},
        q{... barewords don't get modified};

    is _enforce( q{use Module::Name 5.003 'croak'}, 'any' ),
        q{use Module::Name 5.003 'croak', qw< any >},
        q{... but only the first one};

    is _enforce( q{use Module::Name 5.003 croak => 'yes'}, 'any' ),
        q{use Module::Name 5.003 croak => 'yes', qw< any >},
        q{... and of course fat commas};

    is _enforce( q{use Module::Name 5.003 ( 'croak' )}, 'any' ),
        q{use Module::Name 5.003 ( 'croak' ), qw< any >},
        q{... but only the first one};
=cut
};

subtest 'module v-numbers preserve space' => sub {

    is _enforce( q{use Module::Name v1.2.3}, 'any' ),
        q{use Module::Name v1.2.3 qw< any >},
        q{Versions don't need commas};

=pod
    is _enforce( q{use Module::Name v1.2.3 'croak'}, 'any' ),
        q{use Module::Name v1.2.3 'croak', qw< any >},
        q{... but only the first one};
=cut
};

subtest ':all special case' => sub {

    is _enforce( q{use Module::Name ':all'}, 'any' ),
        q{use Module::Name ':all', qw< any >},
        q{conservative levels doesn't make assumptions};

=pod
    is _enforce( { aggression => 1 },
                        q{use Module::Name ':all'}, 'any' ),
        q{use Module::Name ':all'},
        q{... but more aggressive settings assume ':all' exports all};
=cut
};

subtest '-args treated normally' => sub {

    is _enforce( q{use Module::Name -args}, 'any' ),
        q{use Module::Name -args, qw< any >},
        q{-args is treated as just another token};

=pod
    is _enforce( q{use Module::Name -any}, 'any' ),
        q{use Module::Name -any, qw< any >},
        q{... -any is different than 'any'};
=cut
};

subtest '+args treated normally' => sub {

    is _enforce( q{use Module::Name '+args'}, 'any' ),
        q{use Module::Name '+args', qw< any >},
        q{'+args' is treated as just another token};

    is _enforce( q{use Module::Name '+any'}, 'any' ),
        q{use Module::Name '+any', qw< any >},
        q{... '+any' is different than 'any'};
};

subtest '&func treated normally' => sub {

    is _enforce( q{use Module::Name &func}, 'any' ),
        q{use Module::Name &func, qw< any >},
        q{&func is treated as just another token};

    is _enforce( $DEFAULT_CONFIGURATION,
                        q{use Module::Name &any}, 'any' ),
        q{use Module::Name &any, qw< any >},
        q{... &any is different than 'any'};
};

# Can't add imports to perl versions.
#
subtest 'perl versions' => sub {

    subtest 'floating' => sub {
        ok ! _enforce( q{use 5.6}, 'any' ),
            q{floating-point version bails correctly};
 
        ok ! _enforce( q{use 5.002}, 'any' ),
            q{... and three-digit floating bails correctly};
 
        ok ! _enforce( q{use 5.19.5}, 'any' ),
            q{... and multi-period version numbers bails correctly};
    };

    subtest 'v-strings' => sub {
        ok ! _enforce( q{use v5.19.5}, 'any' ),
            q{v-string bails correctly};

        ok ! _enforce( q{use v6-alpha}, 'any' ),
            q{... and v-alpha bails correctly};
    };
};

subtest 'base' => sub {

    is _enforce_base( q{use base}, 'Mine' ),
       q{use base qw< Mine >},
       q{use base ...};

    is _enforce_base( q{use base 3.14}, 'Mine' ),
       q{use base 3.14 qw< Mine >},
       q{use base 3.14 ...};

    is _enforce_base( q{use base $module}, 'Mine' ),
       q{use base $module, qw< Mine >},
       q{use base $module ...};

    subtest 'quote variants' => sub {
        is _enforce_base( q{use base Mine}, 'Yours' ),
           q{use base Mine, qw< Yours >},
           q{use base Mine ...};
 
        is _enforce_base( q{use base 'Mine'}, 'Yours' ),
           q{use base 'Mine', qw< Yours >},
           q{use base 'Mine' ...};
 
        is _enforce_base( q{use base "Mine"}, 'Yours' ),
           q{use base "Mine", qw< Yours >},
           q{use base "Mine" ...};
 
        is _enforce_base( q{use base q{Mine}}, 'Yours' ),
           q{use base q{Mine}, qw< Yours >},
           q{use base q{Mine} ...};
 
        is _enforce_base( q{use base qq{Mine}}, 'Yours' ),
           q{use base qq{Mine}, qw< Yours >},
           q{use base qq{Mine} ...};
    };

    subtest 'list variants' => sub {

        is _enforce_base( q{use base 'Mine', 'Yours'}, 'Other::Name' ),
           q{use base 'Mine', 'Yours', qw< Other::Name >},
           q{use base 'Mine', 'Yours', ...};

        is _enforce_base( q{use base ( 'Mine', 'Yours' )}, 'Other::Name' ),
           q{use base ( 'Mine', 'Yours' ), qw< Other::Name >},
           q{use base ( 'Mine', 'Yours' ) ...};

        subtest 'list delimiter variants' => sub {

            is _enforce_base( q{use base qw( Mine Yours )}, 'Other::Name' ),
               q{use base qw( Mine Yours ), qw< Other::Name >},
               q{use base qw( Mine Yours ) ...};

            is _enforce_base( q{use base qw' Mine Yours '}, 'Other::Name' ),
               q{use base qw' Mine Yours ', qw< Other::Name >},
               q{use base qw' Mine Yours ' ...};

            is _enforce_base( q{use base qw{ Mine Yours }}, 'Other::Name' ),
               q{use base qw{ Mine Yours }, qw< Other::Name >},
               q{use base qw{ Mine Yours } ...};
        };
    };

    is _enforce_base( q{use base qw{ Mine }, qw{ Yours }}, 'Other::Name' ),
       q{use base qw{ Mine }, qw{ Yours }, qw< Other::Name >},
       q{use base qw{ Mine }, qw{ Yours } ...};
};

#subtest 'vars' => sub {
#use vars $foo;
#use vars @foo;
#use vars %foo;
#use vars &foo;
#};

subtest 'module name' => sub {

    is _enforce( q{use My::Name}, 'any' ),
       q{use My::Name qw< any >},
       q{use My::Name};

    subtest 'versioned module' => sub {

        is _enforce( q{use My::Name 5.006}, 'any' ),
           q{use My::Name 5.006 qw< any >},
           q{use My::Name 5.006};

        is _enforce( q{use My::Name v1.2.3}, 'any' ),
           q{use My::Name v1.2.3 qw< any >},
           q{use My::Name v1.2.3};
    };

    subtest 'barewords' => sub {

        is _enforce( q{use My::Name undef}, 'any' ),
           q{use My::Name undef, qw< any >},
           q{use My::Name undef};

        is _enforce( q{use My::Name -foo}, 'any' ),
           q{use My::Name -foo, qw< any >},
           q{use My::Name -foo};

        is _enforce( q{use My::Name +foo}, 'any' ),
           q{use My::Name +foo, qw< any >},
           q{use My::Name +foo};
    };

    subtest 'quoted' => sub {

        is _enforce( q{use My::Name 'foo'}, 'any' ),
           q{use My::Name 'foo', qw< any >},
           q{use My::Name 'foo'};

        is _enforce( q{use My::Name "foo"}, 'any' ),
           q{use My::Name "foo", qw< any >},
           q{use My::Name "foo"};

        is _enforce( q{use My::Name q{foo}}, 'any' ),
           q{use My::Name q{foo}, qw< any >},
           q{use My::Name q{foo}};

        is _enforce( q{use My::Name qq{foo}}, 'any' ),
           q{use My::Name qq{foo}, qw< any >},
           q{use My::Name qq{foo}};

        is _enforce( q{use My::Name qr{foo}}, 'any' ),
           q{use My::Name qr{foo}, qw< any >},
           q{use My::Name qr{foo}};
    };

    subtest 'expression' => sub {

        is _enforce( q{use My::Name \&foo}, 'any' ),
           q{use My::Name \&foo, qw< any >},
           q{use My::Name \&foo};

        is _enforce( q{use My::Name 2 / 3}, 'any' ),
           q{use My::Name 2 / 3, qw< any >},
           q{use My::Name 2 / 3};

        is _enforce( q{use My::Name sub { 'foo' }}, 'any' ),
           q{use My::Name sub { 'foo' }, qw< any >},
           q{use My::Name sub { 'foo' }};

        is _enforce( q{use My::Name pack 'Aa', 0, 1}, 'any' ),
           q{use My::Name pack 'Aa', 0, 1, qw< any >},
           q{use My::Name pack 'Aa', 0, 1};
    };

    subtest 'list' => sub {

        is _enforce( q{use My::Name ()}, 'any' ),
           q{use My::Name (), qw< any >},
           q{use My::Name ()};

        is _enforce( q{use My::Name qw()}, 'any' ),
           q{use My::Name qw(), qw< any >},
           q{use My::Name qw()};

        subtest 'populated list' => sub {
       
            is _enforce( q{use My::Name ( 'all' )}, 'any' ),
               q{use My::Name ( 'all' ), qw< any >},
               q{use My::Name ( 'all' )};

            is _enforce( q{use My::Name qw( all )}, 'any' ),
               q{use My::Name qw( all ), qw< any >},
               q{use My::Name qw( all )};
        };
    };

    subtest 'references' => sub {

        is _enforce( q{use My::Name []}, 'any' ),
           q{use My::Name [], qw< any >},
           q{use My::Name []};

        is _enforce( q{use My::Name {}}, 'any' ),
           q{use My::Name {}, qw< any >},
           q{use My::Name {}};
    };

#use My::Name q(@foo), q/%foo/, q!&foo!, q#*foo#;
#use My::Name "-foo" => q{+foo}, q<:foo> => q[$foo];
#use My::Name q(@foo) => q/%foo/, q!&foo! => q#*foo#;
#use My::Name [ 'foo', ':foo', '&foo' ];
#use My::Name { 'foo' => 1, ':foo' => 2, '&foo' => 3 };
#use My::Name (), 'any';
#use My::Name ( 'foo' ), 'any';
#use My::Name ( 'foo' ) => 'any';
#use My::Name qw(), 'any';
#use My::Name qw( foo :foo &foo @foo $foo %foo *foo ), 'any';
#use My::Name qw( foo :foo &foo @foo $foo %foo *foo ) => 'any';
#use My::Name qw<>, 'any';
#use My::Name qw< foo :foo &foo >, 'any';
};

# And everything all over with 'use My::Name 0.07;'

# And all over again with 'use My::Name foo => ...;'

# And all over again with 'use My::Name 'foo' => ...;'

# And all over again with 'use My::Name -foo => ...;'

# And then inside ()s...


#use $build_package;
#use $module \@{\$args[0]};
#use DBD::${driver};
#use if $] < 5.008 => "IO::Scalar";

### use Module::Name -foo => 1;
### use Module::Name -foo => ['Foo'];
### use Module::Name -foo => [ qw( Foo::Bar ) ];
### use Module::Name -foo => { header_re => qr/\A__([^_]+)__\Z/ };
### use Module::Name -foo => { -module => { 'Example' => 'share', } };

### use Module::Name ( -foo => 1 );
### use Module::Name ('@{}' => \&array_deref);
### use Module::Name ('foo' => 'bar', 'baz' => 'nuts');
### use Module::Name ( grep { /dualvar/ } @Scalar::Util::EXPORT_FAIL )
### use Module::Name ( '$ERRNO', "-no_match_vars", "$EVAL_ERROR" );
### use Module::Name ( '$fooBar', '@EXPORT' );
### use Module::Name ((( '$FOO', '@BAR' )));
### use Module::Name ( foo => '_compare' );
### use Module::Name ( foo => \&_compare );
### use Module::Name ( foo => _compare => foo => 'bar' );
### use Module::Name ( q{""} => sub { (shift)->{msg} }, fallback => 1 );

### use Module::Name qw( :foo foo FOO $FOO &foo -foo _FOO ^foo );
### use Module::Name qw( :all ), distname => "Example_04";
### use Module::Name qw( foo bar ), { ... }
### use Module::Name qw( Module::Name Module::Other );
### use Module::Name qw( @EXPORT_OK );
### use Module::Name qw( $FOO @BAR ), '$BAZ';
### use Module::Name qw( %EXPORT_TAGS );
### use Module::Name qw( $fooBar @EXPORT );
### use Module::Name qw( ../lib lib );

### use Module::Name {{ $eumm_version }};
### use Module::Name v1.2.3 ('foo', 'bar');
### use Module::Name v1.2.3 qw( foo bar );
### use Module::Name tests => 3 + ($ENV{AUTHOR_TESTING} ? 1 : 0);
### use Module::Name tests => @tests * 7;
### use Module::Name is_dev => { set => 'Basic' };
### use Module::Name 5.003 ( qw( import ) );
### use Module::Name 5.003 '-no_match_vars';
### use Module::Name 5.003 ('-no_match_vars');
### use Module::Name 'Exception' => qw( close );
### use Module::Name 5.003 ('@{}' => \&array_deref);
### use Module::Name 5.003 ('${}' => \&scalar_deref);
### use Module::Name '@{}' => \&array_deref;
### use Module::Name -setup => { exports => [ find_dev => \&_build_find_dev, ] };
### use Module::Name 5.003 tests => 1 + ($ENV{AUTHOR_TESTING} ? 1 : 0);
### use Module::Name 'path', 'result', { reasons => sub { [] }, };
### use Module::Name { bar => 42, baz => sub { time } };
### use Module::Name '$ERRNO', "-no_match_vars", "$EVAL_ERROR";
### use Module::Name {{ $plugin->mb_version }};
### 
### use Module::Name 'Module::Name', 'Module::Other';
### use Module::Name catdir( $Module::Name::Bin, qw( .. lib perl5 ) );
### use Module::Name catdir( qw( t 06_violation.d lib ) );
### use Module::Name "$Module::Name::Bin/01_files/lib";
### use Module::Name Module::Name->catdir('lib');
### use Module::Name '@Hashes';
### use Module::Name INFINITY     => ( 9**9**9 );
### use Module::Name IS_MACOS => !! ($^O eq 'MacOS');
### use Module::Name MATCH => qr/ ^ ( \s* ) @{[ REGEX ]} ( \s* ) $ /x;
### use Module::Name 5.003 { BAR => 3, BAZ => 7 };
### use Module::Name SSL_VERIFY_CLIENT_ONCE => Module::Name->new();
### 
### use $dist->{name};
### use $build_package;
### use $pack;
### use 'SomeModule';
### use Module::Name '""'     => sub { shift->name },

### use refactor

=cut

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
