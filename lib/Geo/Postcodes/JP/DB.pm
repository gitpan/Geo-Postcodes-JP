=head1 NAME

Geo::Postcodes::JP::DB - database of Japanese postal codes

=cut

package Geo::Postcodes::JP::DB;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/
                   make_database
                   add_jigyosyo
                   create_database
                   connect_db
                   lookup_postcode
                   test_database
               /;

use warnings;
use strict;
our $VERSION = '0.001';

#line 20 "DB.pm.tmpl"

# Need the postcode-reading function.

use Geo::Postcodes::JP::Process 
qw/
      read_ken_all
      process_line
      read_jigyosyo
      process_jigyosyo_line
  /;

# Require DBI for communicating with the database.
use DBI;

use utf8;
use Lingua::JA::Moji ':all';
use Carp;
use DBI;

# Run "system". This should check for errors but doesn't yet.

sub do_system
{
    my ($command) = @_;
    system ($command);
}

# Make the database from the specified schema file.

sub make_database_from_schema
{
    my ($db_file, $schema_file) = @_;
    do_system ("touch $db_file");
    do_system ("sqlite3 -batch $db_file < $schema_file"); 
}

my $verbose;

my $placename_search_sql = <<EOF;
select id from %s where kanji=? and kana=?
EOF

my %placename_search;

sub search_placename
{
    my ($dbh, $type, $kanji, $kana) = @_;
    if (! $placename_search{$type}) {
        my $sql = sprintf ($placename_search_sql, $type);
        $placename_search{$type} = $dbh->prepare ($sql);
        if (! $placename_search{$type}) {
            die $dbh->errstr;
        }
    }
    if ($verbose) {
        print "Searching for $kanji, $kana\n";
    }
    $placename_search{$type}->execute ($kanji, $kana);
    my $placenames = $placename_search{$type}->fetchall_arrayref ();
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

# There are some cities with the same names in different prefectures,
# for example there is a 府中市 (Fuchuu-shi) in Tokyo and one in
# Hiroshima prefecture, so we need to have a "city_search" routine
# rather than using a generic search for the cities.

my $city_search_sql = <<EOF;
select id from city where kanji=? and ken_id=?
EOF

my $city_search;

sub city_search
{
    my ($dbh, $kanji, $ken_id) = @_;
    if (! $city_search) {
        $city_search = $dbh->prepare ($city_search_sql);
    }
    $city_search->execute ($kanji, $ken_id);
    my $cities = $city_search->fetchall_arrayref ();
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

my $address_search_sql = <<EOF;
select id from address where kanji=? and kana=? and city_id=?
EOF

my $address_search;

sub address_search
{
    my ($dbh, $kanji, $kana, $city_id) = @_;
    if (! $address_search) {
        $address_search = $dbh->prepare ($address_search_sql);
    }
    $address_search->execute ($kanji, $kana, $city_id);
    my $addresses = $address_search->fetchall_arrayref ();
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

=head2

Search using only the kanji for the name.

=cut

my $placename_search_kanji_sql = <<EOF;
select id from %s where kanji=?
EOF

my %placename_search_kanji;

sub search_placename_kanji
{
    my ($dbh, $type, $kanji) = @_;
    if (! $placename_search_kanji{$type}) {
        my $sql = sprintf ($placename_search_kanji_sql, $type);
        $placename_search_kanji{$type} = $dbh->prepare ($sql);
        if (! $placename_search_kanji{$type}) {
            die $dbh->errstr;
        }
    }
    if ($verbose) {
        print "Searching for '$kanji'.\n";
    }
    $placename_search_kanji{$type}->execute ($kanji);
    my $placenames = $placename_search_kanji{$type}->fetchall_arrayref ();
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

# SQL to insert postcodes into the table.

my $postcode_insert_sql = <<EOF;
insert into postcodes (postcode, address_id)
values (?, ?)
EOF

my $postcode_insert_sth;

sub insert_postcode
{
    my ($dbh, $postcode, $address_id) = @_;
    if (! $postcode) {
        die "No postcode";
    }
    if (! $postcode_insert_sth) {
        $postcode_insert_sth = $dbh->prepare ($postcode_insert_sql);
    }
    $postcode_insert_sth->execute ($postcode, $address_id);
}

# SQL to insert postcodes with jigyosyo into the table.

my $jigyosyo_postcode_insert_sql = <<EOF;
insert into postcodes (postcode, address_id, jigyosyo_id)
values (?, ?, ?)
EOF

my $jigyosyo_postcode_insert_sth;

sub jigyosyo_insert_postcode
{
    my ($dbh, $postcode, $address_id, $jigyosyo_id) = @_;
    if (! $postcode) {
        die "No postcode";
    }
    if (0) {
        print "Inserting $postcode\n";
    }
    if (! $jigyosyo_postcode_insert_sth) {
        $jigyosyo_postcode_insert_sth = $dbh->prepare ($jigyosyo_postcode_insert_sql);
    }
    $jigyosyo_postcode_insert_sth->execute ($postcode,
                                            $address_id, $jigyosyo_id);
}

# Format for the SQL to insert kanji, kana into the place name table.

my $jigyosyo_insert_sql = <<'EOF';
insert into jigyosyo (kanji, kana) values (?, ?)
EOF

# Statement handles for inserting place names of various types into
# the database.

my $jigyosyo_insert_sth;

sub jigyosyo_insert
{
    my ($dbh, $kanji, $kana) = @_;
    if ($verbose) {
        print "Inserting jigyosyo $kanji/$kana\n";
    }
    if (! $jigyosyo_insert_sth) {
        $jigyosyo_insert_sth = $dbh->prepare ($jigyosyo_insert_sql);
    }
    $jigyosyo_insert_sth->execute ($kanji, $kana);
    my $id = $dbh->last_insert_id (0, 0, 0, 0);
    return $id;
}


# Format for the SQL to insert kanji, kana into the place name table.

my $ken_insert_sql = <<'EOF';
insert into ken (kanji, kana) values (?, ?)
EOF

# Statement handles for inserting place names of various types into
# the database.

my $ken_insert_sth;

sub ken_insert
{
    my ($dbh, $kanji, $kana) = @_;
    if ($verbose) {
        print "Inserting ken $kanji/$kana\n";
    }
    if (! $ken_insert_sth) {
        $ken_insert_sth = $dbh->prepare ($ken_insert_sql);
    }
    $ken_insert_sth->execute ($kanji, $kana);
    my $id = $dbh->last_insert_id (0, 0, 0, 0);
    return $id;
}

# City

my $city_insert_sql = <<'EOF';
insert into city (kanji, kana, ken_id) values (?, ?, ?)
EOF

my $city_insert_sth;

sub city_insert
{
    my ($dbh, $kanji, $kana, $ken_id) = @_;
    if (! $city_insert_sth) {
        $city_insert_sth = $dbh->prepare ($city_insert_sql);
    }
    $city_insert_sth->execute ($kanji, $kana, $ken_id);
    my $id = $dbh->last_insert_id (0, 0, 0, 0);
    return $id;
}

# Address

my $address_insert_sql = <<'EOF';
insert into address (kanji, kana, city_id) values (?, ?, ?)
EOF

my $address_insert_sth;

sub address_insert
{
    my ($dbh, $kanji, $kana, $city_id) = @_;
    if (! $address_insert_sth) {
        $address_insert_sth = $dbh->prepare ($address_insert_sql);
    }
    $address_insert_sth->execute ($kanji, $kana, $city_id);
    my $id = $dbh->last_insert_id (0, 0, 0, 0);
    return $id;
}


sub connect_db
{
    my ($db_file) = @_;
    my $dbh = DBI->connect ("dbi:SQLite:dbname=$db_file", "", "",
                        {RaiseError => 1} 
                    );
    return $dbh;
}

=head2 insert_postcodes

    insert_postcodes ($db_file, $postcodes);

Insert the postcodes in the array reference C<$postcodes> into the
database specified by C<$db_file>.

=cut

sub insert_postcodes
{
    my ($db_file, $postcodes) = @_;
    my $dbh = connect_db ($db_file);

    $dbh->{AutoCommit} = 0;
    for my $postcode (@$postcodes) {
        # for my $k (keys %$postcode) {
        #     print "$k -> $postcode->{$k}\n";
        # }
        my %ids;
        my %values = process_line ($postcode);
        my $ken_kana = hw2katakana ($values{ken_kana});
        my $ken_kanji = $values{ken_kanji};
        my $ken_id = search_placename ($dbh, 'ken', $ken_kanji, $ken_kana);
        if (! defined $ken_id) {
            $ken_id = ken_insert ($dbh, $ken_kanji, $ken_kana);
        }
        my $city_kana = hw2katakana ($values{city_kana});
        my $city_kanji = $values{city_kanji};
        my $city_id = city_search ($dbh, $city_kanji, $ken_id);
        if (! defined $city_id) {
            $city_id = city_insert ($dbh, $city_kanji, $city_kana, $ken_id);
        }
        my $address_kana = hw2katakana ($values{address_kana});
        my $address_kanji = $values{address_kanji};
        my $address_id = address_search ($dbh, 'address',
                                         $address_kanji, $address_kana,
                                         $city_id);
        if (! defined $address_id) {
            $address_id = address_insert ($dbh, $address_kanji,
                                          $address_kana, $city_id);
        }
        my $pc = $values{new_postcode};
        if (! defined $pc) {
            die "No postcode defined";
        }
        insert_postcode ($dbh, $pc, $address_id);
    }
    $dbh->commit ();
}

=head2 create_database

    create_database (
        db_file => '/path/to/file',
        schema_file => '/path/to/schema/file',
    );

Create the SQLite database specified by C<db_file> using the schema
specified by C<schema_file>.

=cut

sub create_database
{
    my (%inputs) = @_;
    my $db_file = $inputs{db_file};
    my $schema_file = $inputs{schema_file};
    my $verbose = $inputs{verbose};
    if (! $db_file) {
        croak "Specify the database file with db_file => 'file name'";
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
    make_database_from_schema ($db_file, $schema_file);
}

=head2 insert_postcode_file

    insert_postcode_file (
        db_file => '/path/to/database/file',
        postcode_file => '/path/to/postcode/file',
    );

Insert the postcodes in the file specified by C<postcode_file> into
the database specified by C<db_file>.

=cut

sub insert_postcode_file
{
    my (%inputs) = @_;
    my $db_file = $inputs{db_file};
    my $verbose = $inputs{verbose};
    my $postcode_file = $inputs{postcode_file};
    if (! $postcode_file) {
        croak "Specify the file containing the postcodes with postcode_file => 'file name'";
    }
    if ($verbose) {
        print "Reading postcodes from '$postcode_file'.\n";
    }
    my $postcodes = read_ken_all ($postcode_file);
    insert_postcodes ($db_file, $postcodes);
}

=head2 make_database

    make_database (
        db_file => '/path/to/database/file',
        schema_file => '/path/to/schema/file',
        postcode_file => '/path/to/postcode/file',
    );

Make the database specified by C<db_file> using the schema specified
by C<schema_file> from the data in C<postcode_file>.

=cut

sub make_database
{
    my (%inputs) = @_;
    create_database (%inputs);
    insert_postcode_file (%inputs);
}

=head2 lookup_address

    my $address_id = lookup_address ($dbh,
        ken => '北海道',
        city => '',
        address => '',
    );

Look up an address id number from the kanji version of the ken name,
the city name, and the address name.

=cut

my $lookup_sth;

sub lookup_address
{
    my ($dbh, %inputs) = @_;
    if (! $lookup_sth) {
        my $sql = <<EOF;
select address.id  from ken, city, address where 
ken.kanji = ? and
city.kanji = ? and
address.kanji = ? and
ken.id = city.ken_id and
city.id = address.city_id
EOF
        $lookup_sth = $dbh->prepare ($sql);
    }
    $lookup_sth->execute ($inputs{ken}, $inputs{city}, $inputs{address});
    my $return = $lookup_sth->fetchall_arrayref ();
    if (scalar @$return > 1) {
        die "Too many results for $inputs{ken}, $inputs{city}, $inputs{address}";
    }
    if ($return->[0]) {
#        print "@{$return->[0]}\n";
        return @{$return->[0]};
    }
    else {
        return ();
    }
}

=head2 add_jigyosyo

    add_jigyosyo (
        db_file => '/path/to/database/file',
        jigyosyo_file => '/path/to/jigyosyo.csv',
    );

Add the list of place-of-business postcodes from C<jigyosyo_file> to
the database specified by C<db_file>.

=cut

sub add_jigyosyo
{
    my (%inputs) = @_;
    my %total;
    $total{found} = 0;
    my $db_file = $inputs{db_file};
    my $dbh = connect_db ($db_file);
    $dbh->{AutoCommit} = 0;
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
        my $address_id = lookup_address (
            $dbh,
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
            print "$ken, $city, $address, $values{kanji} Not found.\n";
            $ken_id = search_placename_kanji ($dbh, 'ken', $ken);
            $city_id = city_search ($dbh, $city, $ken_id);
            $address_id = address_insert ($dbh, $address, '?', $city_id);
            $total{notfound}++;
        }
        my $jigyosyo_id = jigyosyo_insert ($dbh, $values{kanji}, $values{kana});
#        next;
        jigyosyo_insert_postcode ($dbh, $values{new_postcode},
                                  $address_id, $jigyosyo_id);
    }
    $dbh->commit ();
    print "Found $total{found}: not found $total{notfound}.\n";
}

=head2 lookup_postcode

    my $address = lookup_postcode ('3108610');
    print $address->{ken}->{kanji}, "\n";
    # Prints 茨城県

=cut

my $lookup_postcode_sql = <<EOF;
select * from postcodes, ken, city, address where postcodes.postcode = ? and city.ken_id = ken.id and address.city_id = city.id and postcodes.address_id = address.id;
EOF

my $lookup_postcode_sth;

sub lookup_postcode
{
    my ($dbh, $postcode) = @_;
    if (! $lookup_postcode_sth) {
        $lookup_postcode_sth = $dbh->prepare ($lookup_postcode_sql);
    }
    $lookup_postcode_sth->execute ($postcode);
    my $results = $lookup_postcode_sth->fetchall_arrayref ();
    if (! $results || @$results == 0) {
        return;
    }
    print join ", ", @{$results->[0]};
    print "\n";
    # my %address;
    # @address{qw/

    #            /} = 
    #            @{$results->[0]};
}

=head2 test_database

=cut

sub test_database
{
    my ($db_file, %inputs) = @_;
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

