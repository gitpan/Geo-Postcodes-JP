=encoding UTF-8

=head1 NAME

Geo::Postcodes::JP::DB - database of Japanese postal codes

=head1 SYNOPSIS

    my $o = Geo::Postcodes::JP::DB->new (
        db_file => '/path/to/sqlite/database',
    );
    my $address = $o->lookup_postcode ('3050054');
    print $address->{ken};
    # Prints 茨城県

=head1 DESCRIPTION

This module offers methods to create and access an SQLite database of
Japanese postcodes.

=head1 METHODS

All of these methods make use of an SQLite database file. All of the
fields suffixed with C<_id> are identification numbers of the SQLite
database itself.

=cut

package Geo::Postcodes::JP::DB;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/
                   make_database
                   create_database
               /;

use warnings;
use strict;
our $VERSION = '0.009';

#line 39 "DB.pm.tmpl"

# Need the postcode-reading function.

use Geo::Postcodes::JP::Process 
qw/
      read_ken_all
      process_line
      read_jigyosyo
      process_jigyosyo_line
      improve_postcodes
  /;

# Require DBI for communicating with the database.

use DBI;

# This is for converting the halfwidth (半角) katakana in the post
# office file.

use Lingua::JA::Moji ':all';

use utf8;
use Carp;

sub insert_schema
{
    my ($o, $schema_file) = @_;
    open my $input, "<", $schema_file
    or die "Can't open schema file '$schema_file': $!";
    my $schema = '';
    while (<$input>) {
        $schema .= $_;
    }
    my @schema = split /;/, $schema;
    for my $statement (@schema) {
        $o->{dbh}->do ($statement);
    }
}

# Make the database from the specified schema file.

sub make_database_from_schema
{
    my ($db_file, $schema_file) = @_;
    if (-f $db_file) {
        unlink $db_file
            or die "Error unlinking '$db_file': $!";
    }
    my $o = __PACKAGE__->new (
        db_file => $db_file,
    );
    $o->insert_schema ($schema_file);
    return $o;
}

my $verbose;

=head2 search_placename

    $placename_id = $o->search_placename ($type, $kanji, $kana);

Generic search for a placename of type C<$type> by kanji name
C<$kanji> and kana name C<$kana>. This is only used for the "ken" and
the "jigyosyo" tables, because city and address names are ambiguous.

=cut

sub search_placename
{
    my ($o, $type, $kanji, $kana) = @_;
    if (! $o->{placename_search}{$type}) {
        my $placename_search_sql = <<EOF;
select id from %s where kanji=? and kana=?
EOF
        my $sql = sprintf ($placename_search_sql, $type);
        $o->{placename_search}{$type} = $o->{dbh}->prepare ($sql);
    }
    if ($verbose) {
        print "Searching for $kanji, $kana\n";
    }
    $o->{placename_search}{$type}->execute ($kanji, $kana);
    my $placenames = $o->{placename_search}{$type}->fetchall_arrayref ();
    my $placename_id;
    if ($placenames) {
        if (@$placenames > 1) {
            croak "Search for '$kanji' and '$kana' was ambiguous";
        }
        if (@$placenames == 1) {
            $placename_id = $placenames->[0]->[0];
        }
        else {
            if ($verbose) {
                print "Not found.\n";
            }
        }
    }
    else {
        die "Search failed to return a result";
    }
    return $placename_id;
}

=head2 city_search

    $city_id = $o->city_search ($kanji, $ken_id);

Search for a city named C<$kanji> in prefecture identified by
C<$ken_id>. There are some examples of cities with the same names in
different prefectures. For example there is a 府中市 (Fuchuu-shi) in
Tokyo and one in Hiroshima prefecture. Thus a "city_search" routine
rather than the "search_placename" generic search is needed for
cities.

=cut

sub city_search
{
    my ($o, $kanji, $ken_id) = @_;
    if (! $o->{city_search}) {
        my $city_search_sql = <<EOF;
select id from city where kanji=? and ken_id=?
EOF
        $o->{city_search} = $o->{dbh}->prepare ($city_search_sql);
    }
    $o->{city_search}->execute ($kanji, $ken_id);
    my $cities = $o->{city_search}->fetchall_arrayref ();
    my $city_id;
    if ($cities) {
        if (@$cities > 1) {
            croak "Search for '$kanji' in ken $ken_id was ambiguous";
        }
        if (@$cities == 1) {
            $city_id = $cities->[0]->[0];
        }
        else {
            if ($verbose) {
                print "Not found.\n";
            }
        }
    }
    else {
        die "Search failed to return a result";
    }
    return $city_id;
}

=head2 address_search

    $address_id = $o->address_search ($kanji, $kana, $city_id);

Search for an "address" in a particular city, specified by C<$city_id>.

=cut

sub address_search
{
    my ($o, $kanji, $kana, $city_id) = @_;
    if (! $o->{address_search}) {
        my $address_search_sql = <<EOF;
select id from address where kanji=? and kana=? and city_id=?
EOF
        $o->{address_search} = $o->{dbh}->prepare ($address_search_sql);
    }
    $o->{address_search}->execute ($kanji, $kana, $city_id);
    my $addresses = $o->{address_search}->fetchall_arrayref ();
    my $address_id;
    if ($addresses) {
        if (@$addresses > 1) {
            croak "Search for '$kanji' and '$kana' in city $city_id was ambiguous";
        }
        if (@$addresses == 1) {
            $address_id = $addresses->[0]->[0];
        }
        else {
            if ($verbose) {
                print "Not found.\n";
            }
        }
    }
    else {
        die "Search failed to return a result";
    }
    return $address_id;
}

=head2 search_placename_kanji

    my $place_id = $o->search_placename_kanji ($type, $kanji);

Like L</search_placename>, but search for a place name using only the
kanji for the name.

=cut

my $placename_search_kanji_sql = <<EOF;
select id from %s where kanji=?
EOF

sub search_placename_kanji
{
    my ($o, $type, $kanji) = @_;
    if (! $o->{placename_search_kanji}{$type}) {
        my $sql = sprintf ($placename_search_kanji_sql, $type);
        $o->{placename_search_kanji}{$type} = $o->{dbh}->prepare ($sql);
    }
    $o->{placename_search_kanji}{$type}->execute ($kanji);
    my $placenames = $o->{placename_search_kanji}{$type}->fetchall_arrayref ();
    my $placename_id;
    if ($placenames) {
        if (@$placenames > 1) {
            croak "Search for '$kanji' was ambiguous";
        }
        if (@$placenames == 1) {
            $placename_id = $placenames->[0]->[0];
        }
        else {
            if ($verbose) {
                print "Not found.\n";
            }
        }
    }
    else {
        die "Search failed to return a result";
    }
    return $placename_id;
}

=head2 insert_postcode

    $o->insert_postcode ($postcode, $address_id);

Insert a postcode C<$postcode> into the table of postcodes with
corresponding address C<$address_id>. The address identification
number, C<$address_id>, is usually got from L</address_insert> or
L</address_search>. This method is for addresses which are not
jigyosyo (places of business). Addresses for places of business should
use L</jigyosyo_insert_postcode>.

=cut


# Insert a postcode with an address.

sub insert_postcode
{
    my ($o, $postcode, $address_id) = @_;
    if (! $postcode) {
        die "No postcode";
    }
    if (! $o->{postcode_insert_sth}) {
        # SQL to insert postcodes into the table.
        my $postcode_insert_sql = <<EOF;
insert into postcodes (postcode, address_id)
values (?, ?)
EOF
        $o->{postcode_insert_sth} = $o->{dbh}->prepare ($postcode_insert_sql);
    }
    $o->{postcode_insert_sth}->execute ($postcode, $address_id);
}

=head2 jigyosyo_insert_postcode

    $o->jigyosyo_insert_postcode ($postcode, $address_id, $jigyosyo_id);

Insert a postcode for a "jigyosyo" identified by C<$jigyosyo_id> into
the table. $Jigyosyo_id is usually got from
L</jigyosyo_insert>. C<$Address_id> is as described in the
documentation of L</insert_postcode>.

=cut

sub jigyosyo_insert_postcode
{
    my ($o, $postcode, $address_id, $jigyosyo_id) = @_;
    if (! $postcode) {
        die "No postcode";
    }
    if (0) {
        print "Inserting $postcode\n";
    }
    if (! $o->{jigyosyo_postcode_insert_sth}) {
        # SQL to insert postcodes with jigyosyo into the table.

        my $jigyosyo_postcode_insert_sql = <<EOF;
insert into postcodes (postcode, address_id, jigyosyo_id)
values (?, ?, ?)
EOF
        $o->{jigyosyo_postcode_insert_sth} = $o->{dbh}->prepare ($jigyosyo_postcode_insert_sql);
    }
    $o->{jigyosyo_postcode_insert_sth}->execute ($postcode,
                                            $address_id, $jigyosyo_id);
}

=head2 jigyosyo_insert

    my $jigyosyo_id = $o->jigyosyo_insert ($kanji, $kana, $street_number);

Insert a "jigyosyo" into the table of them with kanji C<$kanji>, kana
C<$kana>, street number C<$street_number>, and return the ID number of
the entry.

=cut

sub jigyosyo_insert
{
    my ($o, $kanji, $kana, $street_number) = @_;
    if ($verbose) {
        print "Inserting jigyosyo $kanji/$kana/$street_number.\n";
    }
    if (! $o->{jigyosyo_insert_sth}) {
        # Format for the SQL to insert kanji, kana into the place name
        # table.
        my $jigyosyo_insert_sql = <<'EOF';
insert into jigyosyo (kanji, kana, street_number) values (?, ?, ?)
EOF
        $o->{jigyosyo_insert_sth} = $o->{dbh}->prepare ($jigyosyo_insert_sql);
    }
    $o->{jigyosyo_insert_sth}->execute ($kanji, $kana, $street_number);
    my $id = $o->{dbh}->last_insert_id (0, 0, 0, 0);
    return $id;
}



=head2 ken_insert

    my $ken_id = $o->ken_insert ($kanji, $kana);

Insert a prefecture into the table of prefectures with the name
C<$kanji> in kanji and C<$kana> in kana. 

=cut

sub ken_insert
{
    my ($o, $kanji, $kana) = @_;
    if ($verbose) {
        print "Inserting ken $kanji/$kana\n";
    }
    if (! $o->{ken_insert_sth}) {
        # Format for the SQL to insert kanji, kana into the place name table.
        my $ken_insert_sql = <<'EOF';
insert into ken (kanji, kana) values (?, ?)
EOF
        $o->{ken_insert_sth} = $o->{dbh}->prepare ($ken_insert_sql);
    }
    $o->{ken_insert_sth}->execute ($kanji, $kana);
    my $id = $o->{dbh}->last_insert_id (0, 0, 0, 0);
    return $id;
}

# City

=head2 city_insert

    my $city_id = $o->city_insert ($kanji, $kana, $ken_id);

Insert a city into the table of cities with kanji name C<$kanji>, kana
name C<$kana>, which is in the prefecture specified by C<$ken_id>.

C<$Ken_id> specifies the prefecture to which the city belongs.

=cut

sub city_insert
{
    my ($o, $kanji, $kana, $ken_id) = @_;
    if (! $o->{city_insert_sth}) {
        my $city_insert_sql = <<'EOF';
insert into city (kanji, kana, ken_id) values (?, ?, ?)
EOF
        $o->{city_insert_sth} = $o->{dbh}->prepare ($city_insert_sql);
    }
    $o->{city_insert_sth}->execute ($kanji, $kana, $ken_id);
    my $id = $o->{dbh}->last_insert_id (0, 0, 0, 0);
    return $id;
}

# Address

=head2 address_insert

    my $address_id = $o->address_insert ($kanji, $kana, $city_id);

Insert an address into the table of addresses with kanji name
C<$kanji>, kana name C<$kana>, and city ID C<$city_id>. This is an
internal routine used in the construction of the database from the
data file.

=cut

sub address_insert
{
    my ($o, $kanji, $kana, $city_id) = @_;
    if (! $o->{address_insert_sth}) {
        my $address_insert_sql = <<'EOF';
insert into address (kanji, kana, city_id) values (?, ?, ?)
EOF
        $o->{address_insert_sth} = $o->{dbh}->prepare ($address_insert_sql);
    }
    $o->{address_insert_sth}->execute ($kanji, $kana, $city_id);
    my $id = $o->{dbh}->last_insert_id (0, 0, 0, 0);
    return $id;
}

=head2 db_connect

    $o->db_connect ('/path/to/database/file');

Connect to the database specified.

=cut

sub db_connect
{
    my ($o, $db_file) = @_;
    $o->{dbh} = DBI->connect ("dbi:SQLite:dbname=$db_file", "", "",
                          {
                              RaiseError => 1,
                              # Set this to '1' to avoid mojibake.
                              sqlite_unicode => 1,
                          }
                      );
    $o->{db_file} = $db_file;
}

=head2 insert_postcodes

    $o->insert_postcodes ($postcodes);

Insert the postcodes in the array reference C<$postcodes> into the
database specified by L</new>.

=cut

sub insert_postcodes
{
    my ($o, $postcodes) = @_;

    $o->{dbh}->{AutoCommit} = 0;
    for my $postcode (@$postcodes) {
        # for my $k (keys %$postcode) {
        #     print "$k -> $postcode->{$k}\n";
        # }
        my %ids;
        my %values = process_line ($postcode);
        my $ken_kana = hw2katakana ($values{ken_kana});
        my $ken_kanji = $values{ken_kanji};
        my $ken_id = $o->search_placename ('ken', $ken_kanji, $ken_kana);
        if (! defined $ken_id) {
            $ken_id = $o->ken_insert ($ken_kanji, $ken_kana);
        }
        my $city_kana = hw2katakana ($values{city_kana});
        my $city_kanji = $values{city_kanji};
        my $city_id = $o->city_search ($city_kanji, $ken_id);
        if (! defined $city_id) {
            $city_id = $o->city_insert ($city_kanji, $city_kana, $ken_id);
        }
        my $address_kana = hw2katakana ($values{address_kana});
        my $address_kanji = $values{address_kanji};
        my $address_id = $o->address_search ('address',
                                         $address_kanji, $address_kana,
                                         $city_id);
        if (! defined $address_id) {
            $address_id = $o->address_insert ($address_kanji,
                                              $address_kana, $city_id);
        }
        my $pc = $values{new_postcode};
        if (! defined $pc) {
            die "No postcode defined";
        }
        $o->insert_postcode ($pc, $address_id);
    }
    $o->{dbh}->commit ();
    $o->{dbh}->{AutoCommit} = 1;
}

=head2 insert_postcode_file

    insert_postcode_file (
        db_file => '/path/to/database/file',
        postcode_file => '/path/to/postcode/file',
    );

Insert the postcodes in the file specified by C<postcode_file> into
the database specified by C<db_file>.

This uses the L<read_ken_all|Geo::Postcodes::JP::Process#read_ken_all> method of L<Geo::Postcodes::JP::Process> to
read the data, and the L<improve_postcodes|Geo::Postcodes::JP::Process#improve_postcodes> function of the same module to improve
the data.

=cut

sub insert_postcode_file
{
    my ($o, %inputs) = @_;
    my $verbose = $inputs{verbose};
    my $postcode_file = $inputs{postcode_file};
    if (! $postcode_file) {
        croak "Specify the file containing the postcodes with postcode_file => 'file name'";
    }
    if ($verbose) {
        print "Reading postcodes from '$postcode_file'.\n";
    }
    my $postcodes = read_ken_all ($postcode_file);
    $postcodes = improve_postcodes ($postcodes);
    $o->insert_postcodes ($postcodes);
}

=head2 lookup_address

    my $address_id = $o->lookup_address (
        ken => '沖縄県',
        city => '宜野湾市',
        address => '上原',
    );

Look up an address id number from the kanji versions of the prefecture
name, the city name, and the address name.

=cut

sub lookup_address
{
    my ($o, %inputs) = @_;
    if (! $o->{lookup_sth}) {
        my $sql = <<EOF;
select address.id  from ken, city, address where 
ken.kanji = ? and
city.kanji = ? and
address.kanji = ? and
ken.id = city.ken_id and
city.id = address.city_id
EOF
        $o->{lookup_sth} = $o->{dbh}->prepare ($sql);
    }
    $o->{lookup_sth}->execute ($inputs{ken}, $inputs{city}, $inputs{address});
    my $return = $o->{lookup_sth}->fetchall_arrayref ();
    if (scalar @$return > 1) {
        die "Too many results for $inputs{ken}, $inputs{city}, $inputs{address}";
    }
    if ($return->[0]) {
        return $return->[0]->[0];
    }
    else {
        return ();
    }
}

=head2 add_jigyosyo

    $o->add_jigyosyo (
        db_file => '/path/to/database/file',
        jigyosyo_file => '/path/to/jigyosyo.csv',
    );

Add the list of place-of-business postcodes from C<jigyosyo_file> to
the database specified by C<db_file>.

=cut

sub add_jigyosyo
{
    my ($o, %inputs) = @_;
    my %total;
    $total{found} = 0;
    $o->{dbh}->{AutoCommit} = 0;
    my $jigyosyo_file = $inputs{jigyosyo_file};
    my $jigyosyo_postcodes = read_jigyosyo ($jigyosyo_file);
    for my $postcode (@$jigyosyo_postcodes) {
        my %values = process_jigyosyo_line ($postcode);
        my $ken = $values{ken_kanji};
        my $city = $values{city_kanji};
        my $address = $values{address_kanji};
        # Remove the "aza" or "ooaza" from the beginning of the name.
        if ($address =~ /(^|大)字/) {
            $address =~ s/(^|大)字//;
        }
        my $address_id = $o->lookup_address (
            ken => $ken,
            city => $city,
            address => $address,
        );                             
        my $ken_id;
        my $city_id;

        if (defined $address_id) {
#            print "Found.\n";
            $total{found}++;
        }
        else {
#            print "$ken, $city, $address, $values{kanji} Not found.\n";
            $ken_id = search_placename_kanji ($o, 'ken', $ken);
            $city_id = city_search ($o, $city, $ken_id);
            $address_id = address_insert ($o, $address, '?', $city_id);
            $total{notfound}++;
        }
        my $jigyosyo_id = jigyosyo_insert ($o, $values{kanji}, $values{kana},
                                           $values{street_number});
#        next;
        if ($address_id == 1) {
            die "BAd aadredd ss id \n";
        }
        jigyosyo_insert_postcode ($o, $values{new_postcode},
                                  $address_id, $jigyosyo_id);
    }
    $o->{dbh}->commit ();
    $o->{dbh}->{AutoCommit} = 1;
#    print "Found $total{found}: not found $total{notfound}.\n";
}

=head2 lookup_jigyosyo

    my $jigyosyo = lookup_jigyosyo ($jigyosyo_id);

Given a jigyosyo id number, return its kanji and kana names and its
street number in a hash reference.

=cut

sub jigyosyo_lookup
{
    my ($o, $jigyosyo_id) = @_;
    my %jigyosyo;
    if (! defined $o->{jigyosyo_lookup_sth}) {
        my $jigyosyo_lookup_sql = <<EOF;
select kanji, kana, street_number from jigyosyo
where
id = ?
EOF
        $o->{jigyosyo_lookup_sth} = $o->{dbh}->prepare ($jigyosyo_lookup_sql);
    }
    $o->{jigyosyo_lookup_sth}->execute ($jigyosyo_id);
    my $r = $o->{jigyosyo_lookup_sth}->fetchall_arrayref ();
    if (! $r) {
        return;
    }
    if (@$r > 1) {
        die "Non-unique jigyosyo id number $jigyosyo_id";
    }
    @jigyosyo{qw/kanji kana street_number/} = @{$r->[0]};
    return \%jigyosyo;
}


=head2 lookup_postcode

    my $addresses = $o->lookup_postcode ('3108610');
    print $address->[0]->{ken}->{kanji}, "\n";
    # Prints 茨城県

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


=cut

my @fields = qw/
                   postcode
                   ken_kanji
                   ken_kana
                   city_kanji
                   city_kana
                   address_kanji
                   address_kana                   jigyosyo_id
               /;
#line 703 "DB.pm.tmpl"

sub make_lookup_postcode_sql
{

    my $sql_fields = join ",", @fields;
    $sql_fields =~ s/_(kanji|kana)/\.$1/g;

    my $lookup_postcode_sql = <<EOF;
select $sql_fields
from postcodes, ken, city, address
where postcodes.postcode = ?
and
city.ken_id = ken.id
and
address.city_id = city.id
and
postcodes.address_id = address.id
EOF
    return $lookup_postcode_sql;
}

sub lookup_postcode
{
    my ($o, $postcode) = @_;
    if (! $o->{lookup_postcode_sth}) {
        my $lookup_postcode_sql = make_lookup_postcode_sql ();
        $o->{lookup_postcode_sth} = $o->{dbh}->prepare ($lookup_postcode_sql);
    }
    $o->{lookup_postcode_sth}->execute ($postcode);
    my $results = $o->{lookup_postcode_sth}->fetchall_arrayref ();
    if (! $results || @$results == 0) {
        return;
    }
    my @addresses;
    for my $result (@$results) {
        my %values;
        @values{@fields} = @{$result};
        if (defined $values{jigyosyo_id}) {
            my $jigyosyo_values = $o->jigyosyo_lookup ($values{jigyosyo_id});
            if ($jigyosyo_values) {
                $values{jigyosyo_kanji} = $jigyosyo_values->{kanji};
                $values{jigyosyo_kana} = $jigyosyo_values->{kana};
                $values{street_number} = $jigyosyo_values->{street_number};
            }
        }
        # Don't leave this in the result, since it is just a database
        # ID number with no meaning to the user.
        delete $values{jigyosyo_id};
        push @addresses, \%values;
    }
    return \@addresses;
}

=head2 new

    my $o = Geo::Postcodes::JP::DB->new (
        db_file => '/path/to/the/sqlite/database/file',
    );

Create a new database-handling object. See also L</create_database> to
create a database file without data, and L</make_database> to create
the database file and insert its data.

=cut

sub new
{
    my ($package, %inputs) = @_;
    my $o = bless {};
    my $db_file = $inputs{db_file};
    if ($db_file) {
        $o->db_connect ($db_file);
    }
    return $o;
}

=head1 FUNCTIONS

=head2 create_database

    my $o = create_database (
        db_file => '/path/to/file',
        schema_file => '/path/to/schema/file',
    );

Create the SQLite database specified by C<db_file> using the schema
specified by C<schema_file>.

The return value is a database handling object as returned by L</new>.

=cut

sub create_database
{
    my (%inputs) = @_;
    my $db_file = $inputs{db_file};
    my $schema_file = $inputs{schema_file};
    my $verbose = $inputs{verbose};
    if (! $db_file) {
        croak "Specify the database file";
    }
    if (! $schema_file) {
        croak "Specify the schema file with schema_file => 'file name'";
    }
    if (-f $db_file) {
        croak "Database file '$db_file' already exists: not recreating.";
    }
    if ($verbose) {
        print "Making database from schema.\n";
    }
    return make_database_from_schema ($db_file, $schema_file);
}

=head2 make_database

    my $o = make_database (
        db_file => '/path/to/database/file',
        schema_file => '/path/to/schema/file',
        postcode_file => '/path/to/postcode/file',
    );

Make the database specified by C<db_file> using the schema specified
by C<schema_file> from the data in C<postcode_file>. The schema is
supplied in the F<db> subdirectory of the distribution in the file
F<db/schema.sql>. This uses L</create_database> to create the database
and L</insert_postcode_file> to insert the data into the database.

The return value is the database handling object, as returned by L</new>.

=cut

sub make_database
{
    my (%inputs) = @_;
    my $o = create_database (%inputs);
    $o->insert_postcode_file (%inputs);
    return $o;
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

