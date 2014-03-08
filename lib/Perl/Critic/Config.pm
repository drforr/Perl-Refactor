##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Config;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use List::MoreUtils qw(any none apply);
use Scalar::Util qw(blessed);

use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Exception::Configuration;
use Perl::Critic::Exception::Configuration::Option::Global::ParameterValue;
use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };
use Perl::Critic::EnforcerFactory;
use Perl::Critic::Theme qw( $RULE_INVALID_CHARACTER_REGEX cook_rule );
use Perl::Critic::UserProfile qw();
use Perl::Critic::Utils qw{
    :booleans :characters :severities :internal_lookup :classification
    :data_conversion
};
use Perl::Critic::Utils::Constants qw<
    :profile_strictness
    $_MODULE_VERSION_TERM_ANSICOLOR
>;
use Perl::Critic::Utils::DataConversion qw< boolean_to_number dor >;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $SINGLE_POLICY_CONFIG_KEY => 'single-enforcer';

#-----------------------------------------------------------------------------
# Constructor

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {
    my ( $self, %args ) = @_;

    # -top or -theme imply that -severity is 1, unless it is already defined
    if ( defined $args{-top} || defined $args{-theme} ) {
        $args{-severity} ||= $SEVERITY_LOWEST;
    }

    my $errors = Perl::Critic::Exception::AggregateConfiguration->new();

    # Construct the UserProfile to get default options.
    my $profile_source = $args{-profile}; # Can be file path or data struct
    my $profile = Perl::Critic::UserProfile->new( -profile => $profile_source );
    my $options_processor = $profile->options_processor();
    $self->{_profile} = $profile;

    $self->_validate_and_save_profile_strictness(
        $args{'-profile-strictness'},
        $errors,
    );

    # If given, these options should always have a true value.
    $self->_validate_and_save_regex(
        'include', $args{-include}, $options_processor->include(), $errors
    );
    $self->_validate_and_save_regex(
        'exclude', $args{-exclude}, $options_processor->exclude(), $errors
    );
    $self->_validate_and_save_regex(
        $SINGLE_POLICY_CONFIG_KEY,
        $args{ qq/-$SINGLE_POLICY_CONFIG_KEY/ },
        $options_processor->single_enforcer(),
        $errors,
    );
    $self->_validate_and_save_color_severity(
        'color_severity_highest', $args{'-color-severity-highest'},
        $options_processor->color_severity_highest(), $errors
    );
    $self->_validate_and_save_color_severity(
        'color_severity_high', $args{'-color-severity-high'},
        $options_processor->color_severity_high(), $errors
    );
    $self->_validate_and_save_color_severity(
        'color_severity_medium', $args{'-color-severity-medium'},
        $options_processor->color_severity_medium(), $errors
    );
    $self->_validate_and_save_color_severity(
        'color_severity_low', $args{'-color-severity-low'},
        $options_processor->color_severity_low(), $errors
    );
    $self->_validate_and_save_color_severity(
        'color_severity_lowest', $args{'-color-severity-lowest'},
        $options_processor->color_severity_lowest(), $errors
    );

    $self->_validate_and_save_verbosity($args{-verbose}, $errors);
    $self->_validate_and_save_severity($args{-severity}, $errors);
    $self->_validate_and_save_top($args{-top}, $errors);
    $self->_validate_and_save_theme($args{-theme}, $errors);
    $self->_validate_and_save_pager($args{-pager}, $errors);
    $self->_validate_and_save_program_extensions(
        $args{'-program-extensions'}, $errors);

    # If given, these options can be true or false (but defined)
    # We normalize these to numeric values by multiplying them by 1;
    $self->{_force} = boolean_to_number( dor( $args{-force}, $options_processor->force() ) );
    $self->{_only}  = boolean_to_number( dor( $args{-only},  $options_processor->only()  ) );
    $self->{_color} = boolean_to_number( dor( $args{-color}, $options_processor->color() ) );
    $self->{_unsafe_allowed} =
        boolean_to_number(
            dor( $args{'-allow-unsafe'}, $options_processor->allow_unsafe()
        ) );
    $self->{_criticism_fatal} =
        boolean_to_number(
            dor( $args{'-criticism-fatal'}, $options_processor->criticism_fatal() )
        );


    # Construct a Factory with the Profile
    my $factory =
        Perl::Critic::EnforcerFactory->new(
            -profile              => $profile,
            -errors               => $errors,
            '-profile-strictness' => $self->profile_strictness(),
        );
    $self->{_factory} = $factory;

    # Initialize internal storage for Policies
    $self->{_all_policies_enabled_or_not} = [];
    $self->{_policies} = [];

    # "NONE" means don't load any policies
    if ( not defined $profile_source or $profile_source ne 'NONE' ) {
        # Heavy lifting here...
        $self->_load_policies($errors);
    }

    if ( $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub add_enforcer {

    my ( $self, %args ) = @_;

    if ( not $args{-enforcer} ) {
        throw_internal q{The -enforcer argument is required};
    }

    my $enforcer  = $args{-enforcer};

    # If the -enforcer is already a blessed object, then just add it directly.
    if ( blessed $enforcer ) {
        $self->_add_enforcer_if_enabled($enforcer);
        return $self;
    }

    # NOTE: The "-config" option is supported for backward compatibility.
    my $params = $args{-params} || $args{-config};

    my $factory       = $self->{_factory};
    my $enforcer_object =
        $factory->create_enforcer(-name=>$enforcer, -params=>$params);
    $self->_add_enforcer_if_enabled($enforcer_object);

    return $self;
}

#-----------------------------------------------------------------------------

sub _add_enforcer_if_enabled {
    my ( $self, $enforcer_object ) = @_;

    my $config = $enforcer_object->__get_config()
        or throw_internal
            q{Enforcer was not set up properly because it does not have }
                . q{a value for its config attribute.};

    push @{ $self->{_all_policies_enabled_or_not} }, $enforcer_object;
    if ( $enforcer_object->initialize_if_enabled( $config ) ) {
        $enforcer_object->__set_enabled($TRUE);
        push @{ $self->{_policies} }, $enforcer_object;
    }
    else {
        $enforcer_object->__set_enabled($FALSE);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _load_policies {

    my ( $self, $errors ) = @_;
    my $factory  = $self->{_factory};
    my @policies = $factory->create_all_policies( $errors );

    return if $errors->has_exceptions();

    for my $enforcer ( @policies ) {

        # If -single-enforcer is true, only load policies that match it
        if ( $self->single_enforcer() ) {
            if ( $self->_enforcer_is_single_enforcer( $enforcer ) ) {
                $self->add_enforcer( -enforcer => $enforcer );
            }
            next;
        }

        # Always exclude unsafe policies, unless instructed not to
        next if not ( $enforcer->is_safe() or $self->unsafe_allowed() );

        # To load, or not to load -- that is the question.
        my $load_me = $self->only() ? $FALSE : $TRUE;

        ## no critic (ProhibitPostfixControls)
        $load_me = $FALSE if     $self->_enforcer_is_disabled( $enforcer );
        $load_me = $TRUE  if     $self->_enforcer_is_enabled( $enforcer );
        $load_me = $FALSE if     $self->_enforcer_is_unimportant( $enforcer );
        $load_me = $FALSE if not $self->_enforcer_is_thematic( $enforcer );
        $load_me = $TRUE  if     $self->_enforcer_is_included( $enforcer );
        $load_me = $FALSE if     $self->_enforcer_is_excluded( $enforcer );


        next if not $load_me;
        $self->add_enforcer( -enforcer => $enforcer );
    }

    # When using -single-enforcer, only one enforcer should ever be loaded.
    if ($self->single_enforcer() && scalar $self->policies() != 1) {
        $self->_add_single_enforcer_exception_to($errors);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _enforcer_is_disabled {
    my ($self, $enforcer) = @_;
    my $profile = $self->_profile();
    return $profile->enforcer_is_disabled( $enforcer );
}

#-----------------------------------------------------------------------------

sub _enforcer_is_enabled {
    my ($self, $enforcer) = @_;
    my $profile = $self->_profile();
    return $profile->enforcer_is_enabled( $enforcer );
}

#-----------------------------------------------------------------------------

sub _enforcer_is_thematic {
    my ($self, $enforcer) = @_;
    my $theme = $self->theme();
    return $theme->enforcer_is_thematic( -enforcer => $enforcer );
}

#-----------------------------------------------------------------------------

sub _enforcer_is_unimportant {
    my ($self, $enforcer) = @_;
    my $enforcer_severity = $enforcer->get_severity();
    my $min_severity    = $self->{_severity};
    return $enforcer_severity < $min_severity;
}

#-----------------------------------------------------------------------------

sub _enforcer_is_included {
    my ($self, $enforcer) = @_;
    my $enforcer_long_name = ref $enforcer;
    my @inclusions  = $self->include();
    return any { $enforcer_long_name =~ m/$_/ixms } @inclusions;
}

#-----------------------------------------------------------------------------

sub _enforcer_is_excluded {
    my ($self, $enforcer) = @_;
    my $enforcer_long_name = ref $enforcer;
    my @exclusions  = $self->exclude();
    return any { $enforcer_long_name =~ m/$_/ixms } @exclusions;
}

#-----------------------------------------------------------------------------

sub _enforcer_is_single_enforcer {
    my ($self, $enforcer) = @_;

    my @patterns = $self->single_enforcer();
    return if not @patterns;

    my $enforcer_long_name = ref $enforcer;
    return any { $enforcer_long_name =~ m/$_/ixms } @patterns;
}

#-----------------------------------------------------------------------------

sub _new_global_value_exception {
    my ($self, @args) = @_;

    return
        Perl::Critic::Exception::Configuration::Option::Global::ParameterValue
            ->new(@args);
}

#-----------------------------------------------------------------------------

sub _add_single_enforcer_exception_to {
    my ($self, $errors) = @_;

    my $message_suffix = $EMPTY;
    my $patterns = join q{", "}, $self->single_enforcer();

    if (scalar $self->policies() == 0) {
        $message_suffix =
            q{did not match any policies (in combination with }
                . q{other enforcer restrictions).};
    }
    else {
        $message_suffix  = qq{matched multiple policies:\n\t};
        $message_suffix .= join qq{,\n\t}, apply { chomp } sort $self->policies();
    }

    $errors->add_exception(
        $self->_new_global_value_exception(
            option_name     => $SINGLE_POLICY_CONFIG_KEY,
            option_value    => $patterns,
            message_suffix  => $message_suffix,
        )
    );

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_regex {
    my ($self, $option_name, $args_value, $default_value, $errors) = @_;

    my $full_option_name;
    my $source;
    my @regexes;

    if ($args_value) {
        $full_option_name = "-$option_name";

        if (ref $args_value) {
            @regexes = @{ $args_value };
        }
        else {
            @regexes = ( $args_value );
        }
    }

    if (not @regexes) {
        $full_option_name = $option_name;
        $source = $self->_profile()->source();

        if (ref $default_value) {
            @regexes = @{ $default_value };
        }
        elsif ($default_value) {
            @regexes = ( $default_value );
        }
    }

    my $found_errors;
    foreach my $regex (@regexes) {
        eval { qr/$regex/ixms }
            or do {
                my $cleaned_error = $EVAL_ERROR || '<unknown reason>';
                $cleaned_error =~
                    s/ [ ] at [ ] .* Config [.] pm [ ] line [ ] \d+ [.] \n? \z/./xms;

                $errors->add_exception(
                    $self->_new_global_value_exception(
                        option_name     => $option_name,
                        option_value    => $regex,
                        source          => $source,
                        message_suffix  => qq{is not valid: $cleaned_error},
                    )
                );

                $found_errors = 1;
            }
    }

    if (not $found_errors) {
        my $option_key = $option_name;
        $option_key =~ s/ - /_/xmsg;

        $self->{"_$option_key"} = \@regexes;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_profile_strictness {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $profile_strictness;

    if ($args_value) {
        $option_name = '-profile-strictness';
        $profile_strictness = $args_value;
    }
    else {
        $option_name = 'profile-strictness';

        my $profile = $self->_profile();
        $source = $profile->source();
        $profile_strictness = $profile->options_processor()->profile_strictness();
    }

    if ( not $PROFILE_STRICTNESSES{$profile_strictness} ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $profile_strictness,
                source          => $source,
                message_suffix  => q{is not one of "}
                    . join ( q{", "}, (sort keys %PROFILE_STRICTNESSES) )
                    . q{".},
            )
        );

        $profile_strictness = $PROFILE_STRICTNESS_FATAL;
    }

    $self->{_profile_strictness} = $profile_strictness;

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_verbosity {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $verbosity;

    if ($args_value) {
        $option_name = '-verbose';
        $verbosity = $args_value;
    }
    else {
        $option_name = 'verbose';

        my $profile = $self->_profile();
        $source = $profile->source();
        $verbosity = $profile->options_processor()->verbose();
    }

    if (
            is_integer($verbosity)
        and not is_valid_numeric_verbosity($verbosity)
    ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $verbosity,
                source          => $source,
                message_suffix  =>
                    'is not the number of one of the pre-defined verbosity formats.',
            )
        );
    }
    else {
        $self->{_verbose} = $verbosity;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_severity {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $severity;

    if ($args_value) {
        $option_name = '-severity';
        $severity = $args_value;
    }
    else {
        $option_name = 'severity';

        my $profile = $self->_profile();
        $source = $profile->source();
        $severity = $profile->options_processor()->severity();
    }

    if ( is_integer($severity) ) {
        if (
            $severity >= $SEVERITY_LOWEST and $severity <= $SEVERITY_HIGHEST
        ) {
            $self->{_severity} = $severity;
        }
        else {
            $errors->add_exception(
                $self->_new_global_value_exception(
                    option_name     => $option_name,
                    option_value    => $severity,
                    source          => $source,
                    message_suffix  =>
                        "is not between $SEVERITY_LOWEST (low) and $SEVERITY_HIGHEST (high).",
                )
            );
        }
    }
    elsif ( not any { $_ eq lc $severity } @SEVERITY_NAMES ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $severity,
                source          => $source,
                message_suffix  =>
                    q{is not one of the valid severity names: "}
                        . join (q{", "}, @SEVERITY_NAMES)
                        . q{".},
            )
        );
    }
    else {
        $self->{_severity} = severity_to_number($severity);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_top {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $top;

    if (defined $args_value and $args_value ne q{}) {
        $option_name = '-top';
        $top = $args_value;
    }
    else {
        $option_name = 'top';

        my $profile = $self->_profile();
        $source = $profile->source();
        $top = $profile->options_processor()->top();
    }

    if ( is_integer($top) and $top >= 0 ) {
        $self->{_top} = $top;
    }
    else {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $top,
                source          => $source,
                message_suffix  => q{is not a non-negative integer.},
            )
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_theme {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $theme_rule;

    if ($args_value) {
        $option_name = '-theme';
        $theme_rule = $args_value;
    }
    else {
        $option_name = 'theme';

        my $profile = $self->_profile();
        $source = $profile->source();
        $theme_rule = $profile->options_processor()->theme();
    }

    if ( $theme_rule =~ m/$RULE_INVALID_CHARACTER_REGEX/xms ) {
        my $bad_character = $1;

        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $theme_rule,
                source          => $source,
                message_suffix  =>
                    qq{contains an illegal character ("$bad_character").},
            )
        );
    }
    else {
        my $rule_as_code = cook_rule($theme_rule);
        $rule_as_code =~ s/ [\w\d]+ / 1 /gxms;

        # eval of an empty string does not reset $@ in Perl 5.6.
        local $EVAL_ERROR = $EMPTY;
        eval $rule_as_code; ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)

        if ($EVAL_ERROR) {
            $errors->add_exception(
                $self->_new_global_value_exception(
                    option_name     => $option_name,
                    option_value    => $theme_rule,
                    source          => $source,
                    message_suffix  => q{is not syntactically valid.},
                )
            );
        }
        else {
            eval {
                $self->{_theme} =
                    Perl::Critic::Theme->new( -rule => $theme_rule );
            }
                or do {
                    $errors->add_exception_or_rethrow( $EVAL_ERROR );
                };
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_pager {
    my ($self, $args_value, $errors) = @_;

    my $pager;
    if ( $args_value ) {
        $pager = defined $args_value ? $args_value : $EMPTY;
    }
    elsif ( $ENV{PERLCRITIC_PAGER} ) {
        $pager = $ENV{PERLCRITIC_PAGER};
    }
    else {
        my $profile = $self->_profile();
        $pager = $profile->options_processor()->pager();
    }

    if ($pager eq '$PAGER') {   ## no critic (RequireInterpolationOfMetachars)
        $pager = $ENV{PAGER};
    }
    $pager ||= $EMPTY;

    $self->{_pager} = $pager;

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_color_severity {
    my ($self, $option_name, $args_value, $default_value, $errors) = @_;

    my $source;
    my $color_severity;
    my $full_option_name;

    if (defined $args_value) {
        $full_option_name = "-$option_name";
        $color_severity = lc $args_value;
    }
    else {
        $full_option_name = $option_name;
        $source = $self->_profile()->source();
        $color_severity = lc $default_value;
    }
    $color_severity =~ s/ \s+ / /xmsg;
    $color_severity =~ s/ \A\s+ //xms;
    $color_severity =~ s/ \s+\z //xms;
    $full_option_name =~ s/ _ /-/xmsg;

    # Should we really be validating this?
    my $found_errors;
    if (
        eval {
            require Term::ANSIColor;
            Term::ANSIColor->VERSION( $_MODULE_VERSION_TERM_ANSICOLOR );
            1;
        }
    ) {
        $found_errors =
            not Term::ANSIColor::colorvalid( words_from_string($color_severity) );
    }

    # If we do not have Term::ANSIColor we can not validate, but we store the
    # values anyway for the benefit of Perl::Critic::ProfilePrototype.

    if ($found_errors) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $full_option_name,
                option_value    => $color_severity,
                source          => $source,
                message_suffix  => 'is not valid.',
            )
        );
    }
    else {
        my $option_key = $option_name;
        $option_key =~ s/ - /_/xmsg;

        $self->{"_$option_key"} = $color_severity;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_program_extensions {
    my ($self, $args_value, $errors) = @_;

    delete $self->{_program_extensions_as_regexes};

    my $extension_list = q{ARRAY} eq ref $args_value ?
        [map {words_from_string($_)} @{ $args_value }] :
        $self->_profile()->options_processor()->program_extensions();

    my %program_extensions = hashify( @{ $extension_list } );

    $self->{_program_extensions} = [keys %program_extensions];

    return;

}

#-----------------------------------------------------------------------------
# Begin ACCESSSOR methods

sub _profile {
    my ($self) = @_;
    return $self->{_profile};
}

#-----------------------------------------------------------------------------

sub all_policies_enabled_or_not {
    my ($self) = @_;
    return @{ $self->{_all_policies_enabled_or_not} };
}

#-----------------------------------------------------------------------------

sub policies {
    my ($self) = @_;
    return @{ $self->{_policies} };
}

#-----------------------------------------------------------------------------

sub exclude {
    my ($self) = @_;
    return @{ $self->{_exclude} };
}

#-----------------------------------------------------------------------------

sub force {
    my ($self) = @_;
    return $self->{_force};
}

#-----------------------------------------------------------------------------

sub include {
    my ($self) = @_;
    return @{ $self->{_include} };
}

#-----------------------------------------------------------------------------

sub only {
    my ($self) = @_;
    return $self->{_only};
}

#-----------------------------------------------------------------------------

sub profile_strictness {
    my ($self) = @_;
    return $self->{_profile_strictness};
}

#-----------------------------------------------------------------------------

sub severity {
    my ($self) = @_;
    return $self->{_severity};
}

#-----------------------------------------------------------------------------

sub single_enforcer {
    my ($self) = @_;
    return @{ $self->{_single_enforcer} };
}

#-----------------------------------------------------------------------------

sub theme {
    my ($self) = @_;
    return $self->{_theme};
}

#-----------------------------------------------------------------------------

sub top {
    my ($self) = @_;
    return $self->{_top};
}

#-----------------------------------------------------------------------------

sub verbose {
    my ($self) = @_;
    return $self->{_verbose};
}

#-----------------------------------------------------------------------------

sub color {
    my ($self) = @_;
    return $self->{_color};
}

#-----------------------------------------------------------------------------

sub pager  {
    my ($self) = @_;
    return $self->{_pager};
}

#-----------------------------------------------------------------------------

sub unsafe_allowed {
    my ($self) = @_;
    return $self->{_unsafe_allowed};
}

#-----------------------------------------------------------------------------

sub criticism_fatal {
    my ($self) = @_;
    return $self->{_criticism_fatal};
}

#-----------------------------------------------------------------------------

sub site_enforcer_names {
    return Perl::Critic::EnforcerFactory::site_enforcer_names();
}

#-----------------------------------------------------------------------------

sub color_severity_highest {
    my ($self) = @_;
    return $self->{_color_severity_highest};
}

#-----------------------------------------------------------------------------

sub color_severity_high {
    my ($self) = @_;
    return $self->{_color_severity_high};
}

#-----------------------------------------------------------------------------

sub color_severity_medium {
    my ($self) = @_;
    return $self->{_color_severity_medium};
}

#-----------------------------------------------------------------------------

sub color_severity_low {
    my ($self) = @_;
    return $self->{_color_severity_low};
}

#-----------------------------------------------------------------------------

sub color_severity_lowest {
    my ($self) = @_;
    return $self->{_color_severity_lowest};
}

#-----------------------------------------------------------------------------

sub program_extensions {
    my ($self) = @_;
    return @{ $self->{_program_extensions} };
}

#-----------------------------------------------------------------------------

sub program_extensions_as_regexes {
    my ($self) = @_;

    return @{ $self->{_program_extensions_as_regexes} }
        if $self->{_program_extensions_as_regexes};

    my %program_extensions = hashify( $self->program_extensions() );
    $program_extensions{'.PL'} = 1;
    return @{
        $self->{_program_extensions_as_regexes} = [
            map { qr< @{[quotemeta $_]} \z >smx } sort keys %program_extensions
        ]
    };
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords colour INI-style -params

=head1 NAME

Perl::Critic::Config - The final derived Perl::Critic configuration, combined from any profile file and command-line parameters.


=head1 DESCRIPTION

Perl::Critic::Config takes care of finding and processing
user-preferences for L<Perl::Critic|Perl::Critic>.  The Config object
defines which Enforcer modules will be loaded into the Perl::Critic
engine and how they should be configured.  You should never really
need to instantiate Perl::Critic::Config directly because the
Perl::Critic constructor will do it for you.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C<< new(...) >>

Not properly documented because you shouldn't be using this.


=back

=head1 METHODS

=over

=item C<< add_enforcer( -enforcer => $enforcer_name, -params => \%param_hash ) >>

Creates a Enforcer object and loads it into this Config.  If the object
cannot be instantiated, it will throw a fatal exception.  Otherwise,
it returns a reference to this Critic.

B<-enforcer> is the name of a
L<Perl::Critic::Enforcer|Perl::Critic::Enforcer> subclass module.  The
C<'Perl::Critic::Enforcer'> portion of the name can be omitted for
brevity.  This argument is required.

B<-params> is an optional reference to a hash of Enforcer parameters.
The contents of this hash reference will be passed into to the
constructor of the Enforcer module.  See the documentation in the
relevant Enforcer module for a description of the arguments it supports.


=item C< all_policies_enabled_or_not() >

Returns a list containing references to all the Enforcer objects that
have been seen.  Note that the state of these objects is not
trustworthy.  In particular, it is likely that some of them are not
prepared to examine any documents.


=item C< policies() >

Returns a list containing references to all the Enforcer objects that
have been enabled and loaded into this Config.


=item C< exclude() >

Returns the value of the C<-exclude> attribute for this Config.


=item C< include() >

Returns the value of the C<-include> attribute for this Config.


=item C< force() >

Returns the value of the C<-force> attribute for this Config.


=item C< only() >

Returns the value of the C<-only> attribute for this Config.


=item C< profile_strictness() >

Returns the value of the C<-profile-strictness> attribute for this
Config.


=item C< severity() >

Returns the value of the C<-severity> attribute for this Config.


=item C< single_enforcer() >

Returns the value of the C<-single-enforcer> attribute for this Config.


=item C< theme() >

Returns the L<Perl::Critic::Theme|Perl::Critic::Theme> object that was
created for this Config.


=item C< top() >

Returns the value of the C<-top> attribute for this Config.


=item C< verbose() >

Returns the value of the C<-verbose> attribute for this Config.


=item C< color() >

Returns the value of the C<-color> attribute for this Config.


=item C< pager() >

Returns the value of the C<-pager> attribute for this Config.


=item C< unsafe_allowed() >

Returns the value of the C<-allow-unsafe> attribute for this Config.


=item C< criticism_fatal() >

Returns the value of the C<-criticsm-fatal> attribute for this Config.


=item C< color_severity_highest() >

Returns the value of the C<-color-severity-highest> attribute for this
Config.


=item C< color_severity_high() >

Returns the value of the C<-color-severity-high> attribute for this
Config.


=item C< color_severity_medium() >

Returns the value of the C<-color-severity-medium> attribute for this
Config.


=item C< color_severity_low() >

Returns the value of the C<-color-severity-low> attribute for this
Config.


=item C< color_severity_lowest() >

Returns the value of the C<-color-severity-lowest> attribute for this
Config.

=item C< program_extensions() >

Returns the value of the C<-program_extensions> attribute for this Config.
This is an array of the file name extensions that represent program files.

=item C< program_extensions_as_regexes() >

Returns the value of the C<-program_extensions> attribute for this Config, as
an array of case-sensitive regexes matching the ends of the file names that
represent program files.

=back


=head1 SUBROUTINES

Perl::Critic::Config has a few static subroutines that are used
internally, but may be useful to you in some way.


=over

=item C<site_enforcer_names()>

Returns a list of all the Enforcer modules that are currently installed
in the Perl::Critic:Enforcer namespace.  These will include modules that
are distributed with Perl::Critic plus any third-party modules that
have been installed.


=back


=head1 CONFIGURATION

Most of the settings for Perl::Critic and each of the Enforcer modules
can be controlled by a configuration file.  The default configuration
file is called F<.perlrefactorrc>.
L<Perl::Critic::Config|Perl::Critic::Config> will look for this file
in the current directory first, and then in your home directory.
Alternatively, you can set the C<PERLCRITIC> environment variable to
explicitly point to a different file in another location.  If none of
these files exist, and the C<-profile> option is not given to the
constructor, then all Policies will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style blocks
that contain key-value pairs separated by '='. Comments should start
with '#' and can be placed on a separate line or after the name-value
pairs if you desire.

Default settings for Perl::Critic itself can be set B<before the first
named block.>  For example, putting any or all of these at the top of
your configuration file will set the default value for the
corresponding Perl::Critic constructor argument.

    severity  = 3                                     #Integer from 1 to 5
    only      = 1                                     #Zero or One
    force     = 0                                     #Zero or One
    verbose   = 4                                     #Integer or format spec
    top       = 50                                    #A positive integer
    theme     = risky + (pbp * security) - cosmetic   #A theme expression
    include   = NamingConventions ClassHierarchies    #Space-delimited list
    exclude   = Variables  Modules::RequirePackage    #Space-delimited list
    color     = 1                                     #Zero or One
    allow_unsafe = 1                                  #Zero or One
    color-severity-highest = bold red                 #Term::ANSIColor
    color-severity-high = magenta                     #Term::ANSIColor
    color-severity-medium =                           #no coloring
    color-severity-low =                              #no coloring
    color-severity-lowest =                           #no coloring
    program-extensions =                              #Space-delimited list

The remainder of the configuration file is a series of blocks like
this:

    [Perl::Critic::Enforcer::Category::EnforcerName]
    severity = 1
    set_themes = foo bar
    add_themes = baz
    arg1 = value1
    arg2 = value2

C<Perl::Critic::Enforcer::Category::EnforcerName> is the full name of a
module that implements the enforcer.  The Enforcer modules distributed
with Perl::Critic have been grouped into categories according to the
table of contents in Damian Conway's book B<Perl Best Practices>. For
brevity, you can omit the C<'Perl::Critic::Enforcer'> part of the module
name.

C<severity> is the level of importance you wish to assign to the
Enforcer.  All Enforcer modules are defined with a default severity value
ranging from 1 (least severe) to 5 (most severe).  However, you may
disagree with the default severity and choose to give it a higher or
lower severity, based on your own coding philosophy.

The remaining key-value pairs are configuration parameters that will
be passed into the constructor of that Enforcer.  The constructors for
most Enforcer modules do not support arguments, and those that do should
have reasonable defaults.  See the documentation on the appropriate
Enforcer module for more details.

Instead of redefining the severity for a given Enforcer, you can
completely disable a Enforcer by prepending a '-' to the name of the
module in your configuration file.  In this manner, the Enforcer will
never be loaded, regardless of the C<-severity> given to the
Perl::Critic::Config constructor.

A simple configuration might look like this:

    #--------------------------------------------------------------
    # I think these are really important, so always load them

    [TestingAndDebugging::RequireUseStrict]
    severity = 5

    [TestingAndDebugging::RequireUseWarnings]
    severity = 5

    #--------------------------------------------------------------
    # I think these are less important, so only load when asked

    [Variables::ProhibitPackageVars]
    severity = 2

    [ControlStructures::ProhibitPostfixControls]
    allow = if unless  #My custom configuration
    severity = 2

    #--------------------------------------------------------------
    # Give these policies a custom theme.  I can activate just
    # these policies by saying (-theme => 'larry + curly')

    [Modules::RequireFilenameMatchesPackage]
    add_themes = larry

    [TestingAndDebugging::RequireTestLables]
    add_themes = curly moe

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::Capitalization]
    [-ValuesAndExpressions::ProhibitMagicNumbers]

    #--------------------------------------------------------------
    # For all other Policies, I accept the default severity, theme
    # and other parameters, so no additional configuration is
    # required for them.

For additional configuration examples, see the F<perlrefactorrc> file
that is included in this F<t/examples> directory of this distribution.


=head1 THE POLICIES

A large number of Enforcer modules are distributed with Perl::Critic.
They are described briefly in the companion document
L<Perl::Critic::EnforcerSummary|Perl::Critic::EnforcerSummary> and in more
detail in the individual modules themselves.


=head1 POLICY THEMES

Each Enforcer is defined with one or more "themes".  Themes can be used
to create arbitrary groups of Policies.  They are intended to provide
an alternative mechanism for selecting your preferred set of Policies.
For example, you may wish disable a certain subset of Policies when
analyzing test programs.  Conversely, you may wish to enable only a
specific subset of Policies when analyzing modules.

The Policies that ship with Perl::Critic are have been broken into the
following themes.  This is just our attempt to provide some basic
logical groupings.  You are free to invent new themes that suit your
needs.

    THEME             DESCRIPTION
    --------------------------------------------------------------------------
    core              All policies that ship with Perl::Critic
    pbp               Policies that come directly from "Perl Best Practices"
    bugs              Policies that prevent or reveal bugs
    maintenance       Policies that affect the long-term health of the code
    cosmetic          Policies that only have a superficial effect
    complexity        Policies that specificaly relate to code complexity
    security          Policies that relate to security issues
    tests             Policies that are specific to test programs

Say C<`perlcritic -list`> to get a listing of all available policies
and the themes that are associated with each one.  You can also change
the theme for any Enforcer in your F<.perlrefactorrc> file.  See the
L<"CONFIGURATION"> section for more information about that.

Using the C<-theme> option, you can combine theme names with
mathematical and boolean operators to create an arbitrarily complex
expression that represents a custom "set" of Policies.  The following
operators are supported

   Operator       Alternative         Meaning
   ----------------------------------------------------------------------------
   *              and                 Intersection
   -              not                 Difference
   +              or                  Union

Operator precedence is the same as that of normal mathematics.  You
can also use parenthesis to enforce precedence.  Here are some
examples:

   Expression                  Meaning
   ----------------------------------------------------------------------------
   pbp * bugs                  All policies that are "pbp" AND "bugs"
   pbp and bugs                Ditto

   bugs + cosmetic             All policies that are "bugs" OR "cosmetic"
   bugs or cosmetic            Ditto

   pbp - cosmetic              All policies that are "pbp" BUT NOT "cosmetic"
   pbp not cosmetic            Ditto

   -maintenance                All policies that are NOT "maintenance"
   not maintenance             Ditto

   (pbp - bugs) * complexity     All policies that are "pbp" BUT NOT "bugs",
                                    AND "complexity"
   (pbp not bugs) and complexity  Ditto

Theme names are case-insensitive.  If C<-theme> is set to an empty
string, then it is equivalent to the set of all Policies.  A theme
name that doesn't exist is equivalent to an empty set.  Please See
L<http://en.wikipedia.org/wiki/Set> for a discussion on set theory.


=head1 SEE ALSO

L<Perl::Critic::OptionsProcessor|Perl::Critic::OptionsProcessor>,
L<Perl::Critic::UserProfile|Perl::Critic::UserProfile>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
