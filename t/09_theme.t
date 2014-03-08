#!perl

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use List::MoreUtils qw(any all none);

use Perl::Refactor::TestUtils;
use Perl::Refactor::EnforcerFactory;
use Perl::Refactor::UserProfile;
use Perl::Refactor::Theme;

use Test::More tests => 66;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

ILLEGAL_RULES: {

    my @invalid_rules = (
        '$cosmetic',    ## no refactor (RequireInterpolationOfMetachars)
        '"cosmetic"',
        '#cosmetic > bugs',
        'cosmetic / bugs',
        'cosmetic % bugs',
        'cosmetic + [bugs - pbp]',
        'cosmetic + {bugs - pbp}',
        'cosmetic @ bugs ^ pbp',
    );

    for my $invalid ( @invalid_rules ) {
        eval { Perl::Refactor::Theme::->new( -rule => $invalid ) };
        like(
            $EVAL_ERROR,
            qr/invalid [ ] character/xms,
            qq{Invalid rule: "$invalid"},
        );
    }
}

#-----------------------------------------------------------------------------

VALID_RULES: {

    my @valid_rules = (
        'cosmetic',
        '!cosmetic',
        '-cosmetic',
        'not cosmetic',

        'cosmetic + bugs',
        'cosmetic - bugs',
        'cosmetic + (bugs - pbp)',
        'cosmetic+(bugs-pbp)',

        'cosmetic || bugs',
        'cosmetic && bugs',
        'cosmetic || (bugs - pbp)',
        'cosmetic||(bugs-pbp)',

        'cosmetic or bugs',
        'cosmetic and bugs',
        'cosmetic or (bugs not pbp)',
    );

    for my $valid ( @valid_rules ) {
        my $theme = Perl::Refactor::Theme->new( -rule => $valid );
        ok( $theme, qq{Valid expression: "$valid"} );
    }
}

#-----------------------------------------------------------------------------

TRANSLATIONS: {
    my %expressions = (
        'cosmetic'                     =>  'cosmetic',
        '!cosmetic'                    =>  '!cosmetic',
        '-cosmetic'                    =>  '!cosmetic',
        'not cosmetic'                 =>  '! cosmetic',
        'cosmetic + bugs',             =>  'cosmetic || bugs',
        'cosmetic - bugs',             =>  'cosmetic && ! bugs',
        'cosmetic + (bugs - pbp)'      =>  'cosmetic || (bugs && ! pbp)',
        'cosmetic+(bugs-pbp)'          =>  'cosmetic||(bugs&& !pbp)',
        'cosmetic or bugs'             =>  'cosmetic || bugs',
        'cosmetic and bugs'            =>  'cosmetic && bugs',
        'cosmetic and (bugs or pbp)'   =>  'cosmetic && (bugs || pbp)',
        'cosmetic + bugs'              =>  'cosmetic || bugs',
        'cosmetic * bugs'              =>  'cosmetic && bugs',
        'cosmetic * (bugs + pbp)'      =>  'cosmetic && (bugs || pbp)',
        'cosmetic || bugs',            =>  'cosmetic || bugs',
        '!cosmetic && bugs',           =>  '!cosmetic && bugs',
        'cosmetic && not (bugs or pbp)'=>  'cosmetic && ! (bugs || pbp)',
    );

    while ( my ($raw, $expected) = each %expressions ) {
        my $cooked = Perl::Refactor::Theme::cook_rule( $raw );
        is( $cooked, $expected, qq{Theme cooking: '$raw' -> '$cooked'});
    }
}


#-----------------------------------------------------------------------------

Perl::Refactor::TestUtils::block_perlrefactorrc();

{
    my $profile = Perl::Refactor::UserProfile->new( -profile => q{} );
    my $factory = Perl::Refactor::EnforcerFactory->new( -profile => $profile );
    my @enforcer_names = Perl::Refactor::EnforcerFactory::site_enforcer_names();
    my @pols = map { $factory->create_enforcer( -name => $_ ) } @enforcer_names;

    #--------------

    my $rule = 'cosmetic';
    my $theme = Perl::Refactor::Theme->new( -rule => $rule );
    my @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) }  @pols;
    ok(
        ( all { has_theme( $_, 'cosmetic' ) } @members ),
        'theme rule: "cosmetic"',
    );

    #--------------

    $rule = 'cosmetic - pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) }  @pols;
    ok(
        ( all  { has_theme( $_, 'cosmetic' ) } @members ),
        'theme rule: "cosmetic - pbp", all has_theme(cosmetic)',
    );
    ok(
        ( none { has_theme( $_, 'pbp')       } @members ),
        'theme rule: "cosmetic - pbp", none has_theme(pbp)',
    );

    $rule = 'cosmetic and not pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) }  @pols;
    ok(
        ( all  { has_theme( $_, 'cosmetic' ) } @members ),
        'theme rule: "cosmetic and not pbp", all has_theme(cosmetic)',
    );
    ok(
        ( none { has_theme( $_, 'pbp')       } @members ),
        'theme rule: "cosmetic and not pbp", none has_theme(pbp)',
    );

    $rule = 'cosmetic && ! pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) }  @pols;
    ok(
        ( all  { has_theme( $_, 'cosmetic' ) } @members ),
        'theme rule: "cosmetic && ! pbp", all has_theme(cosmetic)',
    );
    ok(
        ( none { has_theme( $_, 'pbp')       } @members ),
        'theme rule: "cosmetic && ! pbp", none has_theme(pbp)',
    );

    #--------------

    $rule = 'cosmetic + pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'cosmetic') || has_theme($_, 'pbp') } @members ),
        'theme rule: "cosmetic + pbp"',
    );

    $rule = 'cosmetic || pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'cosmetic') || has_theme($_, 'pbp') } @members ),
        'theme rule: "cosmetic || pbp"',
    );

    $rule = 'cosmetic or pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'cosmetic') || has_theme($_, 'pbp') } @members),
        'theme rule: "cosmetic or pbp"',
    );

    #--------------

    $rule = 'bugs * pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'bugs')  } @members ),
        'theme rule: "bugs * pbp", all has_theme(bugs)',
    );
    ok(
        ( all  { has_theme($_, 'pbp')   } @members ),
        'theme rule: "bugs * pbp", all has_theme(pbp)',
    );

    $rule = 'bugs and pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'bugs')  } @members ),
        'theme rule: "bugs and pbp", all has_theme(bugs)',
    );
    ok(
        ( all  { has_theme($_, 'pbp')   } @members ),
        'theme rule: "bugs and pbp", all has_theme(pbp)',
    );

    $rule = 'bugs && pbp';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'bugs')  } @members ),
        'theme rule: "bugs && pbp", all has_theme(bugs)',
    );
    ok(
        ( all  { has_theme($_, 'pbp')   } @members ),
        'theme rule: "bugs && pbp", all has_theme(pbp)',
    );

    #-------------

    $rule = 'pbp - (danger * security)';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'pbp') } @members ),
        'theme rule: "pbp - (danger * security)", all has_theme(pbp)',
    );
    ok(
        ( none { has_theme($_, 'danger') && has_theme($_, 'security') } @members ),
        'theme rule: "pbp - (danger * security)", none has_theme(danger && security)',
    );

    $rule = 'pbp and ! (danger and security)';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'pbp') } @members ),
        'theme rule: "pbp and not (danger and security)", all has_theme(pbp)',
    );
    ok(
        ( none { has_theme($_, 'danger') && has_theme($_, 'security') } @members ),
        'theme rule: "pbp and not (danger and security)", none has_theme(danger && security)',
    );

    $rule = 'pbp && not (danger && security)';
    $theme = Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    ok(
        ( all  { has_theme($_, 'pbp') } @members ),
        'theme rule: "pbp && not (danger && security)", all has_theme(pbp)',
    );
    ok(
        ( none { has_theme($_, 'danger') && has_theme($_, 'security') } @members ),
        'theme rule: "pbp && not (danger && security)", none has_theme(danger && security)',
    );

    #--------------

    $rule = 'bogus';
    $theme =  Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    is( scalar @members, 0, 'bogus theme' );

    $rule = 'bogus - pbp';
    $theme =  Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    is( scalar @members, 0, 'bogus theme' );

    $rule = q{};
    $theme =  Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    is( scalar @members, scalar @pols, 'empty theme' );

    $rule = q{};
    $theme =  Perl::Refactor::Theme->new( -rule => $rule );
    @members = grep { $theme->enforcer_is_thematic( -enforcer => $_) } @pols;
    is( scalar @members, scalar @pols, 'undef theme' );

    #--------------
    # Exceptions

    $rule = 'cosmetic *(';
    $theme =  Perl::Refactor::Theme->new( -rule => $rule );
    eval{ $theme->enforcer_is_thematic( -enforcer => $pols[0] ) };
    like(
        $EVAL_ERROR,
        qr/syntax [ ] error/xms,
        'invalid theme expression',
    );

}

#-----------------------------------------------------------------------------

sub has_theme {
    my ($enforcer, $theme) = @_;
    return any { $_ eq $theme } $enforcer->get_themes();
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/09_theme.t_without_optional_dependencies.t
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
