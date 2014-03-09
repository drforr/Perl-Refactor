package Perl::Refactor::Exception::Configuration::Option::Enforcer::ExtraParameter;

use 5.006001;
use strict;
use warnings;

use Readonly;

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Refactor::Exception::Configuration::Option::Enforcer::ExtraParameter' => {
        isa         => 'Perl::Refactor::Exception::Configuration::Option::Enforcer',
        description => 'The configuration of a enforcer referred to a non-existant parameter.',
        alias       => 'throw_extra_parameter',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_extra_parameter >;

#-----------------------------------------------------------------------------

sub full_message {
    my ( $self ) = @_;

    my $source = $self->source();
    if ($source) {
        $source = qq{ (found in "$source")};
    }
    else {
        $source = q{};
    }

    my $enforcer = $self->enforcer();
    my $option_name = $self->option_name();

    return
        qq{The $enforcer enforcer doesn't take a "$option_name" option$source.};
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Refactor::Exception::Configuration::Option::Enforcer::ExtraParameter - The configuration referred to a non-existent parameter for a enforcer.

=head1 DESCRIPTION

A representation of the configuration attempting to specify a value
for a parameter that a L<Perl::Refactor::Enforcer|Perl::Refactor::Enforcer>
doesn't have, whether from a F<.perlrefactorrc>, another profile file,
or command line.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 CLASS METHODS

=over

=item C<< throw( enforcer => $enforcer, option_name => $option_name, source => $source ) >>

See L<Exception::Class/"throw">.


=item C<< new( enforcer => $enforcer, option_name => $option_name, source => $source ) >>

See L<Exception::Class/"new">.


=back


=head1 METHODS

=over

=item C<full_message()>

Provide a standard message for values for non-existent parameters for
enforcers.  See L<Exception::Class/"full_message">.


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
