package Geo::Postcodes::JP;

use warnings;
use strict;
our $VERSION = '0.005';


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
    my $address = $gpj->postcode_to_address ('3050053');
    # Now $address contains the address as a hash reference.

=head1 DESCRIPTION

This package contains modules for reading the file of postcodes
supplied by Japan Post and inserting the postcodes into an SQLite
database. The main module provides a way to access the postcodes.

=head2 Building the database

To use this, you need to have built the database already.

The scripts to build the database are in the F<xt> directory of the
distribution. You need to edit these scripts to point to the files you
want to use.

=head1 METHODS

=head2 new

    my $gpj = Geo::Postcodes::JP->new (

=head2 postcode_to_address

    my $address = $gpj->postcode_to_address ('9012204');

Given a postcode, get the corresponding address details. The return
value is a hash reference with the following keys.

=over

=item postcode



=item ken_kanji



=item ken_kana



=item city_kanji



=item city_kana



=item address_kanji



=item address_kana



=item 



=back

If the postcode is a jigyosyo postcode, the result also contains

=over

=item jigyosyo_kanji

The kanji name of the place of business.

=item jigyosyo_kana

The kana name of the place of business. This, unfortunately, is with
small versions of kana all converted into large ones, because this is
the format supplied by the post office.

=item street_number

This is the specific address of the place of business.

=back


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
