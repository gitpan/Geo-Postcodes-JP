=encoding utf8

=head1 NAME

Geo::Postcodes::JP::Process - process Japan Post Office postcode data

=cut

package Geo::Postcodes::JP::Process;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/
                   read_ken_all
                   read_jigyosyo
                   find_duplicates
                   concatenate_multi_line
                   process_line
                   process_jigyosyo_line
                   improve_postcodes
               /;
use utf8;

use warnings;
use strict;
our $VERSION = '0.006';

#line 26 "Process.pm.tmpl"

# Lingua::JA::Moji supplies the routine to convert half-width katakana
# into full-width katakana.

use Lingua::JA::Moji ':all';
use Carp;

# The default name of the address file.

my $ken_all_default = 'KEN_ALL.CSV';

# The default name of the file of postal codes for places of business.

my $jigyosyo_default = 'jigyosyo.csv';

sub open_file
{
    my ($file_name) = @_;
    open my $input, "<:encoding(shift_jis):crlf", $file_name
    or croak "cannot open '$file_name': $!";
    return $input;
}

# These are various types of geographical division in japan, in kanji
# and kana.

my @divisions = (
    [qw/市 シ/],
    [qw/町 チョウ 郡 グン/],
    [qw/町 マチ 郡 グン/],
    [qw/郡 グン/],
    [qw/村 ムラ 郡 グン/],
    [qw/村 ソン 郡 グン/],
    [qw/区 ク 市 シ/],
);

# These are the fields of the postcode file, in order.

my @fields = qw/
number
old_postcode
new_postcode
ken_kana
city_kana
address_kana
ken_kanji
city_kanji
address_kanji
one-region-multiple-postcodes
numbering-start
has-choume
one-postcode-multiple-regions
koushin-no-hyouji
henkou-riyuu

/;
#line 70 "Process.pm.tmpl"

my @jigyosyo_fields = qw/
number
kana
kanji
ken_kanji
city_kanji
address_kanji
street_number
new_postcode
old_postcode
post-office
type
multiple-postcode
Alteration code

/;
#line 77 "Process.pm.tmpl"

=head2 read_ken_all

    my $postcodes_ref = read_ken_all ('KEN_ALL.CSV');

Read the file F<KEN_ALL.CSV>. The return value is an array reference
containing the lines of the postcode file in the same order as the
file itself. The routine issues a fatal error if a problem is
encountered.

The return value is a double indexed array.

=cut

sub read_ken_all
{
    my ($file_name) = @_;
    # If no file name is supplied, assume that the file to be read is
    # the default file name in the current working directory.
    if (! $file_name) {
        $file_name = $ken_all_default;
    }
    # Check whether the file exists.
    if (! -f $file_name) {
        croak "a file called '$file_name' does not exist";
    }
    # This is the return value.
    my @postcodes;
    # Open the data file. The file is in the Shift-JIS format.
    my $input = open_file ($file_name);
    # Read the file line by line.
    while (my $line = <$input>) {
        chomp $line;
        # Remove all double quotes before splitting the line.
        $line =~ s/"//g;
        my @values = split ",", $line;
        push @postcodes, \@values;
    }
    # Close the input file.
    close $input or croak "cannot close '$file_name': $!";
    # Return an array containing all the postal codes.
    return \@postcodes;
}

=head2 process_line

    my %values = process_line ($line);

Turn a line of the postcode file into a hash of its values.

The values of the hash are 

=over


=item number

The JIS code number for the region. The JIS standards for regions of
Japan are numbered JIS X 0401 (1973) for the prefecture identification
codes, and JIS X0402 (2003) identification codes for cities, towns and
villages.



=item old_postcode

The old three or five digit postcode.



=item new_postcode

The new seven digit postcode.



=item ken_kana

The kana version of the prefecture.



=item city_kana

The kana version of the city.



=item address_kana

The kana version of the address.



=item ken_kanji

The kanji version of the prefecture.



=item city_kanji

The kanji version of the city.



=item address_kanji

The kanji version of the address.



=item one-region-multiple-postcodes

This is 1 if the same address has more than one postcode, zero
otherwise.



=item numbering-start

Indicates if numbering starts, 1 if so.



=item has-choume

Indicates there is a division into "choume".



=item one-postcode-multiple-regions

This is 1 if the same postcode covers more than one region, zero
otherwise.



=item koushin-no-hyouji

0 = no change, 1 = change, 2 = delete



=item henkou-riyuu

Reason for change.



=item 




=back

See also the L<Japan Post explanation of the KEN_ALL.CSV file|http://www.post.japanpost.jp/zipcode/dl/readme.html> in Japanese.

=cut

#line 146 "Process.pm.tmpl"

sub process_line
{
    my ($line) = @_;
    my %values;
    # @fields is defined above.
    @values{@fields} = @$line;
    return %values;
}

=head2 concatenate_multi_line

    $postcodes = concatenate_multi_line ($postcodes);

Concatenate single entries which are spread on multiple lines.

=cut

use constant ADDRESS_KANA => 5;
use constant ADDRESS_KANJI => 8;
use constant NEW_POSTCODE => 2;

# Add more data to a single entry which spans multiple lines of the
# input file.

sub add_more_data
{
    my ($multi_lines, $line) = @_;
#    print "Adding @$line to @$multi_lines\n";
    for my $i (0..$#$line) {
        if ($i eq ADDRESS_KANA || $i eq ADDRESS_KANJI) {
            if (defined $multi_lines->[$i]) {
                $multi_lines->[$i] .= $line->[$i];
            }
            else {
                # Set from the first value.
                $multi_lines->[$i] = $line->[$i];
            }
        }
        else {
            if (defined $multi_lines->[$i]) {
                # This is not the first value.
                if ($line->[$i] ne $multi_lines->[$i]) {
                    warn "Mismatch $line->[$i] and $multi_lines->[$i]";
                }
            }
            else {
                # Set from the first value.
                $multi_lines->[$i] = $line->[$i];
            }
        }
    }
}


use utf8;

# Given the list of postcodes and the list of duplicates, turn the
# duplicates which are multiline into non-multiline.

sub concatenate_multi_line
{
    my ($postcodes, $duplicates) = @_;
    my @concatenated;
    my $total_brackets = 0;
    my %done;
    for my $line (@$postcodes) {
        my $postcode = $line->[NEW_POSTCODE];
        if ($duplicates->{$postcode}) {
            my @dups = @{$duplicates->{$postcode}};
            my $multi;
            my @multi_lines;
            for my $ln (@dups) {
                if ($done{$ln}) {
                    next;
                }
                my $line = $postcodes->[$ln];
                my $address_kana = $line->[ADDRESS_KANA];
                my $address_kanji = $line->[ADDRESS_KANJI];
                if ($address_kanji =~ /\x{FF08}/) {
#                    print "$postcode\n";
#                    print "match: (\n";
                    $multi = 1;
                    $total_brackets++;
                }
                if ($address_kanji =~ /\x{FF09}/) {
#                    print "$address_kanji\n";
#                    print "match: )\n";
                }
                if ($multi) {
#                    print "In multi: $address_kanji\n";
                    add_more_data (\@multi_lines, $line);
                }
                $done{$ln} = 1;
            }
            if ($multi) {
                push @concatenated, \@multi_lines;
            }
            else {
                # Was not a multiline, so add each entry separately.
                for my $ln (@dups) {
                    if ($done{$ln}) {
                        next;
                    }
                    my $mline = $postcodes->[$ln];
                    push @concatenated, $mline;
                }
            }
        }
        else {
            push @concatenated, $line;
        }
    }
#    print $total_brackets;
    return \@concatenated;
}

=head2 find_duplicates

    my $duplicates = find_duplicates ();

Make a hash whose keys are postcodes which have duplicate references,
and whose values are array references to arrays of offsets in the
postcode file.

=cut

sub find_duplicates
{
    my ($postcodes) = @_;
    my %postcodes;
    my %duplicates;
    my $ln = 0;
    for my $line (@$postcodes) {
        my $postcode = $line->[2];
        if ($postcodes{$postcode}) {
            $duplicates{$postcode} = 1;
        }
        push @{$postcodes{$postcode}}, $ln;
        $ln++;
    }
    for my $k (keys %duplicates) {
        $duplicates{$k} = $postcodes{$k};
    }
    return \%duplicates;
}

=head2 read_jigyosyo

    my $jigyosyo_data = read_jigyosyo ('/path/to/jigyosyo/csv/file');

=cut

sub read_jigyosyo
{
    my ($input_file) = @_;

    my @jigyosho_postcodes;
#    my $input_file = 'jigyosyo.csv';
    open my $input, "<:encoding(shift-jis)", $input_file or die $!;
    binmode STDOUT, ":utf8";
    while (<$input>) {
        my @fields = split /,\s*/, $_;
        if (scalar @fields != 13) {
            die "$input_file:$.: $_\n";
        }
        for (@fields) {
            s/^"(.*)"$/$1/;
        }
        push @jigyosho_postcodes, \@fields;
    }
    close $input or die $!;
    return \@jigyosho_postcodes;
}

=head2 process_jigyosyo_line

    my %values = process_jigyosyo_line ($line);

Turn the array reference C<$line> into a hash of its values using the
fields.

The values of the hash are 

=over


=item number

As for the main postcode file.



=item kana

The name of the place of business in kana.



=item kanji

The name of the place of business in kanji.



=item ken_kanji

The kanji version of the prefecture name.



=item city_kanji

The kanji version of the city name.



=item address_kanji

The kanji version of the address name.



=item street_number

The exact street number of the place of business.



=item new_postcode

As for the "ken_all" fields.



=item old_postcode

As for the "ken_all" fields.



=item post-office

The post office which handles mail for this postcode.



=item type

0=Large company
1=Private



=item multiple-postcode

0=Not multiple, also 1,2,3.



=item Alteration code

0=No change
1=New addition
2=Deleted



=item 




=back

See also the L<Japan Post explanation of the JIGYOSYO.CSV file|http://www.post.japanpost.jp/zipcode/dl/jigyosyo/readme.html> in Japanese.

=cut

#line 347 "Process.pm.tmpl"

sub process_jigyosyo_line
{
    my ($line) = @_;
    my %values;
    @values{@jigyosyo_fields} = @$line;
    $values{kana} = hw2katakana ($values{kana});
    return %values;
}

=head2 improve_postcodes

    $postcodes = improve_postcodes ($postcodes);

Improve the postcodes as much as possible by unifying lines etc.

=cut

sub improve_postcodes
{
    my ($postcodes) = @_;
    my $duplicates = find_duplicates ($postcodes);
    $postcodes = concatenate_multi_line ($postcodes, $duplicates);
    return $postcodes;
}

1;

__END__

=head1 TERMINOLOGY

=over

=item postcode

In this module, "postcode" is the translation used for the Japanese
term "yuubin bangou" (郵便番号). They might be called "postal codes"
or even "zip codes" by some. 

This module only deals with the seven-digit modern postcodes. It does
not deal with the old three and five digit postcodes, these are not
parsed from the file.

=item ken

"Ken" means the Japanese system of prefectures, which includes the
"ken" divisions as well as the "do/fu/to" divisions, with "do" used
for Hokkaido, "fu" for Osaka and Kyoto, and "to" for the Tokyo
metropolis. These are got from the module using the word "ken".

See also L<the sci.lang.japan FAQ on Japanese addresses|http://www.sljfaq.org/afaq/addresses.html>.

=item city

In this module, "city" is the term used to point to the second field
in the postcode data file. Some of these are actually cities, like
"Mito-shi" (水戸市), the city of Mito in Ibaraki prefecture. However,
some of them are not really cities but other geographical
subdivisions.

=item address

In this module, "address" is the term used to point to the third field
in the postcode data file. This is called 町域 (chouiki) by the Post Office.

=item jigyosyo

In this module, "jigyosyo" is the term used to point to places of
business. Some places of business have their own postcodes,

=back

For example, in the following data file entry, "3100004" is the
postcode, "茨城県" (Ibaraki-ken) is the "ken", "水戸市" (Mito-shi) is
the "city", and "青柳町" (Aoyagicho) is the "address".

08201,"310  ","3100004","ｲﾊﾞﾗｷｹﾝ","ﾐﾄｼ","ｱｵﾔｷﾞﾁｮｳ","茨城県","水戸市","青柳町",0,0,0,0,0,0



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



# Local variables:
# mode: perl
# End:
