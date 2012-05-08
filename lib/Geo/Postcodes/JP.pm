package Geo::Postcodes::JP;

use warnings;
use strict;
our $VERSION = '0.006';


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
    my $addresses = $object->{db}->lookup_postcode ($postcode);
    return $addresses;
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

This package contains a series of modules for handling the files of
postcodes supplied by Japan Post. L<Geo::Postcodes::JP::Update>
downloads the data files.  L<Geo::Postcodes::JP::Process> parses the
data files, and can improve the data.  L<Geo::Postcodes::JP::DB>
inserts the postcode data read by the processing module into an SQLite
database. The main module provides a way to access the postcodes in an
existing SQLite database.

=head2 Building the database

To build the database, use the scripts in the F<xt> directory of the
distribution. You need to edit these scripts to point to the files you
want to use.

The script F<update.pl> uses the L<Geo::Postcodes::JP::Update> module
to update the CSV files on your hard disk from the Japan Post Office
web site. It downloads two files, F<ken_all.zip> and
F<jigyosyo.zip>. The user then needs to unzip these files.

The script F<insert-all.pl> inserts the file F<KEN_ALL.CSV> into a
database specified in the module F<PostCodeFiles.pm> found in the
F<xt> directory. The user needs to edit this file to point to
whereever the database files should be created. The script
F<insert-jigyosyo.pl> inserts the F<JIGYOSYO.CSV> into the database
specified. Again, the user needs to edit the F<PostCodeFiles.pm>
module to specify where things should go.

=head1 METHODS

=head2 new

    my $gpj = Geo::Postcodes::JP->new (
        db_file => '/path/to/database/file',
    );

"New" creates a new postcode-lookup object. The parameter is the path
to the database file, which is the file created in the stage
L<Building the database> above.

=head2 postcode_to_address

    my $address = $gpj->postcode_to_address ('9012204');

Given a postcode, get the corresponding address details. The return
value is a hash reference with the following keys.

=over

=item postcode

The seven-digit postcode itself, for example 0708033.


=item ken_kanji

The kanji form of the prefecture name, for example 北海道.


=item ken_kana

The kana form of the prefecture name, for example ホッカイドウ.


=item city_kanji

The kanji form of the city name, for example 旭川市. In some instances
this data will consist of "gun" and "machi" or "shi" and "ku"
information rather than just a city name, depending on the information
in the Japan Post Office file itself.


=item city_kana

The kana form of the city name, for example アサヒカワシ.


=item address_kanji

The final part of the address in kanji, for example 神居町雨紛.


=item address_kana

The final part of the address in kana, for example カムイチョウウブン.


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

#line 86 "Main.pm.tmpl"

=head1 SEE ALSO

L<Number::ZipCode::JP> - validate Japanese zip-codes. This is a huge
regular expression made from the same data file which this module
reads, which can be used to validate a Japanese postal code.

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Geo::Postcodes::JP and associated files are copyright (c) 
2012 Ben Bullock.

You may use, copy, modify and distribute Geo::Postcodes::JP under the
same terms as the Perl programming language itself.

=cut


#line 95 "Main.pm.tmpl"

# Local variables:
# mode: perl
# End:
