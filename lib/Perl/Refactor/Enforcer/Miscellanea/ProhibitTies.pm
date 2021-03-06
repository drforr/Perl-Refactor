package Perl::Refactor::Enforcer::Miscellanea::ProhibitTies;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Refactor::Utils qw{ :severities :classification };
use base 'Perl::Refactor::Enforcer';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Tied variable used};
Readonly::Scalar my $EXPL => [ 451 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                       }
sub default_severity     { return $SEVERITY_LOW            }
sub default_themes       { return qw(core pbp maintenance) }
sub applies_to           { return 'PPI::Token::Word'       }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem ne 'tie';
    return if ! is_function_call( $elem );
    return $self->violation( $DESC, $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Refactor::Enforcer::Miscellanea::ProhibitTies - Do not use C<tie>.


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Refactor|Perl::Refactor>
distribution.


=head1 DESCRIPTION

Conway discourages using C<tie> to bind Perl primitive variables to
user-defined objects.  Unless the tie is done close to where the
object is used, other developers probably won't know that the variable
has special behavior.  If you want to encapsulate complex behavior,
just use a proper object or subroutine.


=head1 CONFIGURATION

This Enforcer is not configurable except for the standard options.


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
