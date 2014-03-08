##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Exception::Configuration::Option::Enforcer::ParameterValue;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :characters };

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration::Option::Enforcer::ParameterValue' => {
        isa         => 'Perl::Critic::Exception::Configuration::Option::Enforcer',
        description => 'A problem with the value of a parameter for a enforcer.',
        alias       => 'throw_enforcer_value',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_enforcer_value >;

#-----------------------------------------------------------------------------

sub full_message {
    my ( $self ) = @_;

    my $source = $self->source();
    if ($source) {
        $source = qq{ found in "$source"};
    }
    else {
        $source = $EMPTY;
    }

    my $enforcer = $self->enforcer();
    my $option_name = $self->option_name();
    my $option_value =
        defined $self->option_value()
            ? $DQUOTE . $self->option_value() . $DQUOTE
            : '<undef>';
    my $message_suffix = $self->message_suffix() || $EMPTY;

    return
            qq{The value for the $enforcer "$option_name" option }
        .   qq{($option_value)$source $message_suffix};
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::Configuration::Option::Enforcer::ParameterValue - A problem with the value of a parameter for a enforcer.

=head1 DESCRIPTION

A representation of a problem found with the value of a parameter for
a L<Perl::Critic::Enforcer|Perl::Critic::Enforcer>, whether from a
F<.perlrefactorrc>, another profile file, or command line.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 CLASS METHODS

=over

=item C<< throw( enforcer => $enforcer, option_name => $option_name, option_value => $option_value, source => $source, message_suffix => $message_suffix ) >>

See L<Exception::Class/"throw">.


=item C<< new( enforcer => $enforcer, option_name => $option_name, option_value => $option_value, source => $source, message_suffix => $message_suffix ) >>

See L<Exception::Class/"new">.


=back


=head1 METHODS

=over

=item C<full_message()>

Provide a standard message for enforcer parameter value problems.  See
L<Exception::Class/"full_message">.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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