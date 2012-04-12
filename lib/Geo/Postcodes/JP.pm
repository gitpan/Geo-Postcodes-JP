=head1 NAME

Geo::Postcodes::JP - handle the Japan Post Office postal code data

=cut

package Geo::Postcodes::JP;

use warnings;
use strict;
our $VERSION = '0.001';


use Geo::Postcodes::JP::DB qw/connect_db lookup_postcode/;

sub new
{
    my ($package, %inputs) = @_;
    my $db_file = $inputs{db_file};
    my $object = {};
    $object->{dbh} = connect_db ($db_file);
    return bless $object;
}

sub postcode_to_address
{
    my ($object, $postcode) = @_;
    return lookup_postcode ($object->{dbh}, $postcode);
}

1;

__END__

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Geo::Postcodes::JP and associated files are copyright (c) 
2012 Ben Bullock.

You may use, copy, modify and distribute Geo::Postcodes::JP under the
same terms as the Perl programming language itself.

=cut



# Local variables:
# mode: perl
# End:
