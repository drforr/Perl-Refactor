package Perl::Refactor::Enforcer::BuiltinFunctions::RequireBlockMap;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Refactor::Utils qw{ :severities :classification :ppi };
use base 'Perl::Refactor::Enforcer';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Expression form of "map"};
Readonly::Scalar my $EXPL => [ 169 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'map';
    return if ! is_function_call($elem);

    my $arg = first_arg($elem);
    return if !$arg;
    return if $arg->isa('PPI::Structure::Block');

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Refactor::Enforcer::BuiltinFunctions::RequireBlockMap - Write C<map { $_ =~ /$pattern/ } @list> instead of C<map /$pattern/, @list>.


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Refactor|Perl::Refactor>
distribution.


=head1 DESCRIPTION

The expression forms of C<grep> and C<map> are awkward and hard to
read.  Use the block forms instead.

    @matches = grep   /pattern/,   @list;        #not ok
    @matches = grep { /pattern/ }  @list;        #ok

    @mapped = map   transform($_),   @list;      #not ok
    @mapped = map { transform($_) }  @list;      #ok



=head1 CONFIGURATION

This Enforcer is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Refactor::Enforcer::BuiltinFunctions::ProhibitStringyEval|Perl::Refactor::Enforcer::BuiltinFunctions::ProhibitStringyEval>

L<Perl::Refactor::Enforcer::BuiltinFunctions::RequireBlockGrep|Perl::Refactor::Enforcer::BuiltinFunctions::RequireBlockGrep>


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
