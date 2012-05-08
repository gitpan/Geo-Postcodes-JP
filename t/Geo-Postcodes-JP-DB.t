# This file tests the operation of the submodule which connects to the
# SQLite database of postcode information.

use warnings;
use strict;
use Test::More tests => 13;
BEGIN { use_ok ('Geo::Postcodes::JP::DB') };
use Geo::Postcodes::JP::DB qw/create_database/;
use FindBin;
use utf8;

# The directory with the schema in it, "../db".

my $db_dir = "$FindBin::Bin/../db";

# The file name (including the directory) of the schema file.

my $schema_file = "$db_dir/schema.sql";

# Test whether the schema file exists.

ok (-f $schema_file, "The schema file exists where it is supposed to.");

# A test database, in the current directory, which we will create
# using the schema.

my $test_db = "$FindBin::Bin/test.db";

# Delete a test database from a previous test, for example if the test
# script failed before cleaning (removing this file).

rm_db ();

# Try to create the database from the schema using the
# "create_database" routine.

eval {
    create_database (
    db_file => $test_db,
        schema_file => $schema_file,
    );
};

# Test whether an error occurred in creating the database.

ok (! $@, "Create_database did not die.");

# Test whether the database file exists.

ok (-f $test_db, "The database file was created.");

# Remove the generated file.

rm_db ();

my $test_pc_file = "$FindBin::Bin/KEN_SOME.CSV";

my $o;

$o = Geo::Postcodes::JP::DB::make_database (
    db_file => $test_db,
    schema_file => $schema_file,
    postcode_file => $test_pc_file,
);
#print "\n";

ok ($o, "make database returned something");

# Test whether the database file exists.

ok (-f $test_db, "The database file was created.");

# This is the file which contains a testing version of the jigyosyo
# information.

my $test_jigyosyo_file = "$FindBin::Bin/jigyosyo-some.csv";

eval {
    $o->add_jigyosyo (
        jigyosyo_file => $test_jigyosyo_file,
    );
};

# Check the above did not die.

ok (! $@, "Added jigyosyo information did not die");

# Spot check the inserted data.

my $nishionuma = $o->lookup_postcode ('3050054');

ok (defined $nishionuma, "Got a defined result for Nishi Oonuma postcode");

ok (scalar @$nishionuma == 1, "Only one postcode for Nishi Oonuma");

ok ($nishionuma->[0]->{address_kanji} eq '西大沼',
    "The expected address kanji was found");
ok ($nishionuma->[0]->{ken_kanji} eq '茨城県',
    "The expected ken kanji was found");

my $mitoshiyakusho = $o->lookup_postcode ('3108610');

ok (defined $mitoshiyakusho, "Got a defined result for Mito City Hall");

ok ($mitoshiyakusho->[0]->{jigyosyo_kanji} eq '水戸市役所',
    "Got correct kanji name of Mito City Hall");

# Remove the generated file.

rm_db ();

exit;

# Remove the test database file.

sub rm_db
{
    if (-f $test_db) {
        unlink $test_db or die $!;
    }
}

# Local variables:
# mode: perl
# End:
