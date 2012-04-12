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
               /;
use utf8;

use warnings;
use strict;
our $VERSION = '0.001';

#line 19 "Process.pm.tmpl"

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

my @fields = qw/number old_postcode new_postcode
		ken_kana  city_kana  address_kana
		ken_kanji city_kanji address_kanji
		a b c d e f/;

my @jigyosyo_fields = qw/
                            number
                            kana
                            kanji
                            ken_kanji
                            city_kanji
                            address_kanji
                            number
                            new_postcode
                            old_postcode
                            a b c d
                        /;

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

=item something

Generate these entries with the template toolkit.

=back

=cut

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

use utf8;

sub concatenate_multi_line
{
    my ($postcodes, $duplicates) = @_;
    my @concatenated;
    my $total_brackets = 0;
    for my $line (@$postcodes) {
        my $postcode = $line->[NEW_POSTCODE];
        if ($duplicates->{$postcode}) {
            my @dups = @{$duplicates->{$postcode}};
            my $multi;
            for my $ln (@dups) {
                my $line = $postcodes->[$ln];
                my $address_kana = $line->[ADDRESS_KANA];
                my $address_kanji = $line->[ADDRESS_KANJI];
                if ($address_kanji =~ /\x{FF08}/) {
                    print "$postcode\n";
                    print "match: (\n";
                    $multi = 1;
                    $total_brackets++;
                }
                if ($address_kanji =~ /\x{FF09}/) {
                    print "$address_kanji\n";
                    print "match: )\n";
                }
                if ($multi) {
                    print "In multi: $address_kanji\n";
                }
            }
            if (! $multi) {
                for my $ln (@dups) {
                    my $mline = $postcodes->[$ln];
                    push @concatenated, $mline;
                }
            }
        }
        else {
            push @concatenated, $line;
        }
    }
    print $total_brackets;
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

sub read_jigyosyo
{
    my ($input_file) = @_;

    # The following are descriptions of the jigyosyo data
    # fields. Where these correspond to the fields in the usual
    # postcode file (city_kanji etc.) the names used below are the
    # same names as used in the usual postcode file. There are four
    # fields at the end consisting of a name in kanji like 札幌 and
    # three numbers, which I don't know the function of. There is no
    # documentation of what these numbers are at
    # http://www.post.japanpost.jp/zipcode/dl/jigyosyo/index.html
    # so I have just used "a, b, c, d" to label them.

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

sub process_jigyosyo_line
{
    my ($line) = @_;
    my %values;
    @values{@jigyosyo_fields} = @$line;
    $values{kana} = hw2katakana ($values{kana});
    return %values;
}

1;

__END__

=head1 TERMINOLOGY

=over

=item ken

=item city

=item address

=back

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
