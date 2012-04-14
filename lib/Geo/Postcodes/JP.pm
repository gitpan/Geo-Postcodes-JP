package Geo::Postcodes::JP;

use warnings;
use strict;
our $VERSION = '0.004';


use Geo::Postcodes::JP::DB;

sub new
{
    my ($package, %inputs) = @_;
    my $db_file = $inputs{db_file};
    my $object = {};
    $object->{db} = Geo::Postcodes::JP::DB->new (%inputs);
    return bless $object;
}

sub postcode_to_address
{
    my ($object, $postcode) = @_;
    my $address = $object->{db}->lookup_postcode ($postcode);
    return $address;
}

1;

__END__

=head1 NAME

Geo::Postcodes::JP - handle the Japan Post Office postal code data

=head1 SYNOPSIS

    my $gpj = Geo::Postcodes::JP->new (
        db_file => '/path/to/database/file',
    );
    my $address = $gpj->postcode_to_address ();
    # Now $address contains the address as a hash reference

=head1 DESCRIPTION

To use this, you need to have built the database already.

The scripts to build the database are in the F<xt> directory of the
distribution. You need to edit these scripts to point to the files you
want to use.

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
