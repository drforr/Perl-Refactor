package Perl::Refactor::ProfilePrototype;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Refactor::Config qw{};
use Perl::Refactor::Enforcer qw{};
use Perl::Refactor::Utils qw{ :characters };
use overload ( q{""} => 'to_string' );

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    my $enforcers = $args{-enforcers} || [];
    $self->{_enforcers} = [ sort _by_type @{ $enforcers } ];

    my $comment_out_parameters = $args{'-comment-out-parameters'};
    if (not defined $comment_out_parameters) {
        $comment_out_parameters = 1;
    }
    $self->{_comment_out_parameters} = $comment_out_parameters;

    my $configuration = $args{'-config'};
    if (not $configuration) {
        $configuration = Perl::Refactor::Config->new(-profile => $EMPTY);
    }
    $self->{_configuration} = $configuration;


    return $self;
}

#-----------------------------------------------------------------------------

sub _get_enforcers {
    my ($self) = @_;

    return $self->{_enforcers};
}

sub _comment_out_parameters {
    my ($self) = @_;

    return $self->{_comment_out_parameters};
}

sub _configuration {
    my ($self) = @_;

    return $self->{_configuration};
}

#-----------------------------------------------------------------------------

sub _line_prefix {
    my ($self) = @_;

    return $self->_comment_out_parameters() ? q{# } : $EMPTY;
}

#-----------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $prefix = $self->_line_prefix();
    my $configuration = $self->_configuration();

    my $prototype = "# Globals\n";

    $prototype .= $prefix;
    $prototype .= q{severity = };
    $prototype .= $configuration->severity();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{force = };
    $prototype .= $configuration->force();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{only = };
    $prototype .= $configuration->only();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{allow-unsafe = };
    $prototype .= $configuration->unsafe_allowed();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{profile-strictness = };
    $prototype .= $configuration->profile_strictness();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{color = };
    $prototype .= $configuration->color();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{pager = };
    $prototype .= $configuration->pager();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{top = };
    $prototype .= $configuration->top();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{verbose = };
    $prototype .= $configuration->verbose();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{include = };
    $prototype .= join $SPACE, $configuration->include();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{exclude = };
    $prototype .= join $SPACE, $configuration->exclude();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{single-enforcer = };
    $prototype .= join $SPACE, $configuration->single_enforcer();
    $prototype .= "\n";

    $prototype .= $prefix;
    $prototype .= q{theme = };
    $prototype .= $configuration->theme()->rule();
    $prototype .= "\n";

    foreach my $item (qw<
        color-severity-highest
        color-severity-high
        color-severity-medium
        color-severity-low
        color-severity-lowest
        >) {
        ( my $accessor = $item ) =~ s/ - /_/gmsx;
        $prototype .= $prefix;
        $prototype .= "$item = ";
        $prototype .= $configuration->$accessor;
        $prototype .= "\n";
    }

    $prototype .= $prefix;
    $prototype .= q{program-extensions = };
    $prototype .= join $SPACE, $configuration->program_extensions();

    Perl::Refactor::Enforcer::set_format( $self->_proto_format() );

    return $prototype . "\n\n" . join q{}, map { "$_" } @{ $self->_get_enforcers() };
}

#-----------------------------------------------------------------------------

# About "%{\\n%\\x7b# \\x7df\n${prefix}%n = %D\\n}O" below:
#
# The %0 format for a enforcer specifies how to format parameters.
# For a parameter %f specifies the full description.
#
# The problem is that both of these need to take options, but String::Format
# doesn't allow nesting of {}.  So, to get the option to the %f, the braces
# are hex encoded.  I.e., assuming that comment_out_parameters is in effect,
# the parameter sees:
#
#    \n%{# }f\n# %n = %D\n

sub _proto_format {
    my ($self) = @_;

    my $prefix = $self->_line_prefix();

    return <<"END_OF_FORMAT";
# %a
[%p]
${prefix}set_themes                         = %t
${prefix}add_themes                         =
${prefix}severity                           = %s
${prefix}maximum_violations_per_document    = %v
%{\\n%\\x7b# \\x7df\\n${prefix}%n = %D\\n}O%{${prefix}Cannot programmatically discover what parameters this enforcer takes.\\n}U

END_OF_FORMAT

}

#-----------------------------------------------------------------------------

sub _by_type { return ref $a cmp ref $b }

1;

__END__

=pod

=head1 NAME

Perl::Refactor::ProfilePrototype - Generate an initial Perl::Refactor profile.


=head1 DESCRIPTION

This is a helper class that generates a prototype of a
L<Perl::Refactor|Perl::Refactor> profile (e.g. a F<.perlrefactorrc> file.
There are no user-serviceable parts here.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


=head1 CONSTRUCTOR

=over

=item C<< new( -enforcers => \@POLICY_OBJECTS ) >>

Returns a reference to a new C<Perl::Refactor::ProfilePrototype> object.


=back


=head1 METHODS

=over

=item to_string()

Returns a string representation of this C<ProfilePrototype>.  See
L<"OVERLOADS"> for more information.


=back


=head1 OVERLOADS

When a
L<Perl::Refactor::ProfilePrototype|Perl::Refactor::ProfilePrototype> is
evaluated in string context, it produces a multi-line summary of the
enforcer name, default themes, and default severity for each
L<Perl::Refactor::Enforcer|Perl::Refactor::Enforcer> object that was given to
the constructor of this C<ProfilePrototype>.  If the Enforcer supports
an additional parameters, they will also be listed (but
commented-out).  The format is suitable for use as a F<.perlrefactorrc>
file.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
