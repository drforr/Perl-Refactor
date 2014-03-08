#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::UserProfile;

use Test::More tests => 41;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

# Create profile from hash

{
    my %enforcer_params = (min_elements => 4);
    my %profile_hash = ( '-NamingConventions::Capitalization' => {},
                         'CodeLayout::ProhibitQuotedWordLists' => \%enforcer_params );

    my $up = Perl::Critic::UserProfile->new( -profile => \%profile_hash );

    # Using short enforcer names
    is(
        $up->enforcer_is_enabled('CodeLayout::ProhibitQuotedWordLists'),
        1,
        'CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Now using long enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        1,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Enforcer::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Using bogus enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't enabled>,
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't disabled>,
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::Bogus'),
        {},
        q<Bogus Enforcer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Create profile from array

{
    my %enforcer_params = (min_elements => 4);
    my @profile_array = ( q{ [-NamingConventions::Capitalization] },
                          q{ [CodeLayout::ProhibitQuotedWordLists]           },
                          q{ min_elements = 4                         },
    );


    my $up = Perl::Critic::UserProfile->new( -profile => \@profile_array );

    # Now using long enforcer names
    is(
        $up->enforcer_is_enabled('CodeLayout::ProhibitQuotedWordLists'),
        1,
        'CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Now using long enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        1,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Enforcer::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Using bogus enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't enabled>,
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't disabled>,
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::Bogus'),
        {},
        q<Bogus Enforcer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Create profile from string

{
    my %enforcer_params = (min_elements => 4);
    my $profile_string = <<'END_PROFILE';
[-NamingConventions::Capitalization]
[CodeLayout::ProhibitQuotedWordLists]
min_elements = 4
END_PROFILE

    my $up = Perl::Critic::UserProfile->new( -profile => \$profile_string );

    # Now using long enforcer names
    is(
        $up->enforcer_is_enabled('CodeLayout::ProhibitQuotedWordLists'),
        1,
        'CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Now using long enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        1,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Enforcer::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Using bogus enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't enabled>,
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't disabled>,
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::Bogus'),
        {},
        q<Bogus Enforcer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Test long enforcer names

{
    my %enforcer_params = (min_elements => 4);
    my $long_profile_string = <<'END_PROFILE';
[-Perl::Critic::Enforcer::NamingConventions::Capitalization]
[Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists]
min_elements = 4
END_PROFILE

    my $up = Perl::Critic::UserProfile->new( -profile => \$long_profile_string );

    # Now using long enforcer names
    is(
        $up->enforcer_is_enabled('CodeLayout::ProhibitQuotedWordLists'),
        1,
        'CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Now using long enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        1,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists is enabled.',
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Enforcer::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists'),
        \%enforcer_params,
        'Perl::Critic::Enforcer::CodeLayout::ProhibitQuotedWordLists got the correct configuration.',
    );

    # Using bogus enforcer names
    is(
        $up->enforcer_is_enabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't enabled>,
    );
    is(
        $up->enforcer_is_disabled('Perl::Critic::Enforcer::Bogus'),
        q{},
        q<Bogus Enforcer isn't disabled>,
    );
    is_deeply(
        $up->raw_enforcer_params('Perl::Critic::Enforcer::Bogus'),
        {},
        q<Bogus Enforcer doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $code_ref = sub { return };
    eval { Perl::Critic::UserProfile->new( -profile => $code_ref ) };
    like(
        $EVAL_ERROR,
        qr/Can't [ ] load [ ] UserProfile/xms,
        'Invalid profile type',
    );

    eval { Perl::Critic::UserProfile->new( -profile => 'bogus' ) };
    like(
        $EVAL_ERROR,
        qr/Could [ ] not [ ] parse [ ] profile [ ] "bogus"/xms,
        'Invalid profile path',
    );

    my $invalid_syntax = '[Foo::Bar'; # Missing "]"
    eval { Perl::Critic::UserProfile->new( -profile => \$invalid_syntax ) };
    like(
        $EVAL_ERROR,
        qr/Syntax [ ] error [ ] at [ ] line/xms,
        'Invalid profile syntax',
    );

    $invalid_syntax = 'severity 2'; # Missing "="
    eval { Perl::Critic::UserProfile->new( -profile => \$invalid_syntax ) };
    like(
        $EVAL_ERROR,
        qr/Syntax [ ] error [ ] at [ ] line/xms,
        'Invalid profile syntax',
    );

}

#-----------------------------------------------------------------------------
# Test profile finding

{
    my $expected = local $ENV{PERLCRITIC} = 'foo';
    my $got = Perl::Critic::UserProfile::_find_profile_path();
    is( $got, $expected, 'PERLCRITIC environment variable');
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/10_userprofile.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
