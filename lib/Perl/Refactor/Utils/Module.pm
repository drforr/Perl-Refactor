package Perl::Refactor::Utils::Module;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Scalar::Util qw< blessed readonly >;

use Exporter 'import';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    get_include_list
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub get_include_list {
    my $node = shift;

    return if not $element;

    return $root->find( sub {
        $_[1]->isa('PPI::Statement::Include') and
            $_[1]->type eq 'use'
    } );
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords

=head1 NAME

Perl::Refactor::Utils::Module - Utility functions for dealing with Perl modules.


=head1 DESCRIPTION

Provides utilities for module-level attributes


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<get_include_list( $root )>

Given the root L<PPI::Element|PPI::Element> node, this subroutine returns
all of the C<use> statements in the module. If no C<use> statements are found,
returns undef.


=back


=head1 AUTHOR

Jeff Goff <jgoff@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2014 Jeffrey Goff <jgoff@cpan.org>

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
