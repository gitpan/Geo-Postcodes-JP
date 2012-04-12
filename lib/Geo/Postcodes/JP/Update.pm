=head1 NAME

Geo::Postcodes::JP::Update - update Japan Post Office postcode data

=cut

package Geo::Postcodes::JP::Update;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/update_files/;

use warnings;
use strict;
our $VERSION = '0.002';


use Lingua::JA::FindDates;

=head2 update_files

=cut

sub update_files
{
    # Update the files.
}

1;

__END__

=head1 SEE ALSO

L<Number::ZipCode::JP> - validate Japanese zip-codes.

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Geo::Postcodes::JP and associated files are copyright (c) 
2012 Ben Bullock.

You may use, copy, modify and distribute Geo::Postcodes::JP under the
same terms as the Perl programming language itself.

=cut



=cut

# Local variables:
# mode: perl
# End:
