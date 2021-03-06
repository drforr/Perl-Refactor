package Perl::Refactor::Exception::Configuration::Option::Enforcer;

use 5.006001;
use strict;
use warnings;

use Perl::Refactor::Utils qw{ &enforcer_short_name };

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Refactor::Exception::Configuration::Option::Enforcer' => {
        isa         => 'Perl::Refactor::Exception::Configuration::Option',
        description => 'A problem with the configuration of a enforcer.',
        fields      => [ qw{ enforcer } ],
    },
);

#-----------------------------------------------------------------------------

sub new {
    my ($class, %options) = @_;

    my $enforcer = $options{enforcer};
    if ($enforcer) {
        $options{enforcer} = enforcer_short_name($enforcer);
    }

    return $class->SUPER::new(%options);
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Refactor::Exception::Configuration::Option::Enforcer - A problem with configuration of a enforcer.

=head1 DESCRIPTION

A representation of a problem found with the configuration of a
L<Perl::Refactor::Enforcer|Perl::Refactor::Enforcer>, whether from a
F<.perlrefactorrc>, another profile file, or command line.

This is an abstract class.  It should never be instantiated.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<enforcer()>

The short name of the enforcer that had configuration problems.


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
