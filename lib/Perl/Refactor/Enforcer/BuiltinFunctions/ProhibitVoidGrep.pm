package Perl::Refactor::Enforcer::BuiltinFunctions::ProhibitVoidGrep;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Refactor::Utils qw{ :severities :classification is_in_void_context };
use base 'Perl::Refactor::Enforcer';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"grep" used in void context};
Readonly::Scalar my $EXPL => q{Use a "for" loop instead};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw( core maintenance ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'grep';
    return if not is_function_call($elem);
    return if not is_in_void_context($elem);

    return $self->violation( $DESC, $EXPL, $elem );
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Refactor::Enforcer::BuiltinFunctions::ProhibitVoidGrep - Don't use C<grep> in void contexts.


=head1 AFFILIATION

This Enforcer is part of the core L<Perl::Refactor|Perl::Refactor>
distribution.


=head1 DESCRIPTION

C<map> and C<grep> are intended to be pure functions, not mutators.
If you want to iterate with side-effects, then you should use a proper
C<for> or C<foreach> loop.

    grep{ print frobulate($_) } @list;           #not ok
    print map{ frobulate($_) } @list;            #ok

    grep{ $_ = lc $_ } @list;                    #not ok
    for( @list ){ $_ = lc $_  };                 #ok

    map{ push @frobbed, frobulate($_) } @list;   #not ok
    @frobbed = map { frobulate($_) } @list;      #ok


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
