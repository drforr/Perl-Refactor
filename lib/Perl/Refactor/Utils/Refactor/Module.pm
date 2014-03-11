package Perl::Refactor::Utils::Refactor::Module;

use 5.006001;
use strict;
use warnings;

use Readonly;
use List::MoreUtils qw( any );

#use Perl::Refactor::Utils qw{ :characters :booleans };
use Perl::Refactor::Utils::Module qw{ get_include_list };

use Exporter 'import';

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw(
    enforce_module_includes
);

#-----------------------------------------------------------------------------

sub enforce_module_includes {
    my ( $node, $enforcement ) = @_;
    my $use_statements = get_include_list( $node->top );
    my @edit_list;
    for my $statement ( @{ $use_statements } ) {
        my @imports = get_import_list_from_include_statement( $statement );
    }
}

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Refactor::Utils::Refactor::Module - Utilities for module-level refactoring

=head1 DESCRIPTION

Provides utilities to refactor at the module level


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<enforce_module_includes( $node, $enforcements )>

Enforce inclusion of all modules in C<$enforcements>. If a module needs a
particular method exported (or a tag), add it as an arrayref associated with
the module. Note that this only enumerates C<use> statements, and does not
take into account C<no Module::Name;> or C<require 'Module::Name';>.
New C<use> statements are added before the first non-pragma C<use> statement.

=back


=head1 AUTHOR

Jeff Goff <jgoff@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014 Jeff Goff.

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
