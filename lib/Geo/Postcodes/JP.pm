package Geo::Postcodes::JP;

use warnings;
use strict;
our $VERSION = '0.012';


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

=encoding UTF-8

=head1 NAME

Geo::Postcodes::JP - handle Japan Post Office postal code data

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

Given a postcode, get the corresponding address details. If the
postcode is found, the return value is an array reference containing
one or more hash references with the following keys. If the postcode
is not found, the return value is the undefined value.

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


=head1 Building the database

The module comes with abbreviated versions of the input CSV files and
generates short versions of the database for its testing.

To build the full version of the database, it is necessary to download
and process the post office's files. These files are not included in
the distribution because they are very large files and change monthly.

The scripts required are in the F<xt> directory of the
distribution. These files must be edited to point to the location of
the input files and the database files on the user's system.

The script F<update.pl> uses the L<Geo::Postcodes::JP::Update> module
to update the CSV files on the user's local storage from the Japan
Post Office web site. It downloads two files, F<ken_all.zip> and
F<jigyosyo.zip>. The user then needs to unzip these files.

The script F<insert-all.pl> inserts the file F<KEN_ALL.CSV> into a
database specified in the helper module F<PostCodeFiles.pm> found in
the F<xt> directory. The user needs to edit the helper module to point
to whereever the database files should be created. The script
F<insert-jigyosyo.pl> inserts the F<JIGYOSYO.CSV> into the database
specified. Again, the user needs to edit the F<PostCodeFiles.pm>
module to specify where things should go.

=head1 SEE ALSO

L<http://www.post.japanpost.jp/zipcode/download.html>: This is the
main page for Japan Post's data downloads. Unfortunately the download
page is not available in English. (If you want to find the download
URLs but cannot read Japanese, the accompanying module 
L<Geo::Postcodes::JP::Update> contains the URLs needed to download the data
without having to search through this page for the correct address.)

L<Number::ZipCode::JP> - validate Japanese zip-codes. This is a huge
regular expression made from the same data file which this module
reads, which can be used to validate a Japanese postal code.

L<http://www.lemoda.net/japan/postcodes/index.html>: This is the
module author's "scrapbook" page containing information from the
internet about the postcode file. It includes links to relevant blog
posts and links to software systems for handling the data.

=head1 TERMINOLOGY

=over

=item Postcode

In this module, "postcode" is the translation used for the Japanese
term "yuubin bangou" (郵便番号). They might be called "postal codes"
or even "zip codes" by some. 

This module only deals with the seven-digit modern postcodes
introduced in 1998. It does not handle the three and five digit
postcodes which were used until 1998.

=item Ken

In this module, "ken" in a variable name means the Japanese system of
prefectures, which includes the "ken" divisions as well as the
"do/fu/to" divisions, with "do" used for Hokkaido, "fu" for Osaka and
Kyoto, and "to" for the Tokyo metropolis. These are got from the
module using the word "ken".

See also L<the sci.lang.japan FAQ on Japanese addresses|http://www.sljfaq.org/afaq/addresses.html>.

=item City

In this module, "city" is the term used to point to the second field
in the postcode data file. Some of these are actually cities, like
"Mito-shi" (水戸市), the city of Mito in Ibaraki prefecture. However,
some of them are not really cities but other geographical
subdivisions, such as gun/machi or shi/ku combinations.

=item Address

In this module, "address" is the term used to point to the third field
in the postcode data file. This is called 町域 (chouiki) by the Post
Office.

For example, in the following data file entry, "3100004" is the
postcode, "茨城県" (Ibaraki-ken) is the "ken", "水戸市" (Mito-shi) is
the "city", and "青柳町" (Aoyagicho) is the "address".

    08201,"310  ","3100004","ｲﾊﾞﾗｷｹﾝ","ﾐﾄｼ","ｱｵﾔｷﾞﾁｮｳ","茨城県","水戸市","青柳町",0,0,0,0,0,0

=item Jigyosyo

In this module, "jigyosyo" is the term used to point to places of
business. Some places of business have their own postcodes. 

The term "jigyosyo" is used because it is the post office's own
romanization, but this is actually an error and should be either
I<jigyōsho> or I<zigyôsyo> in standard romanizations of Japanese, or
I<jigyosho> in simplified Hepburn. See L<the Sci.Lang.Japan FAQ page
on Japanese romanization|http://www.sljfaq.org/afaq/kana-roman.html>.

=item Street number

In this module "street number" is an arbitrary way of describing the
final part of the address, which may actually specify a variety of
things, such as the ban-chi, or even what floor of a building the
postcode refers to.

The street number field is mostly relevant for the jigyosyo postcodes,
but also crops up in some of the addresses, especially for rural
areas.

=back



=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Geo::Postcodes::JP and associated files are copyright (c) 
2012 Ben Bullock.

You may use, copy, modify and distribute Geo::Postcodes::JP under the
same terms as the Perl programming language itself.

=cut


#line 117 "Main.pm.tmpl"

# Local variables:
# mode: perl
# End:
