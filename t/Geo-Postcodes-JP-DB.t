# This file tests the operation of the submodule which connects to the
# SQLite database of postcode information.

use warnings;
use strict;
use Test::More tests => 6;
BEGIN { use_ok ('Geo::Postcodes::JP::DB') };
use Geo::Postcodes::JP::DB qw/create_database make_database/;
use FindBin;
use File::Spec;

# The directory with the schema in it, "../db".

my $db_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir (), "db");

# The file name (including the directory) of the schema file.

my $schema_file = "$db_dir/schema.sql";

# Test whether the schema file exists.

ok (-f $schema_file, "The schema file exists where it is supposed to.");

# A test database, in the current directory, which we will create
# using the schema.

my $test_db = File::Spec->catpath (undef, $FindBin::Bin, "test.db");

# Delete a test database from a previous test, for example if the test
# script failed before cleaning (removing this file).

rm_db ();

# Try to create the database from the schema using the
# "create_database" routine.

eval {
    create_database (
        schema_file => $schema_file,
        db_file => $test_db,
    );
};

# Test whether an error occurred in creating the database.

ok (! $@, "Create_database did not die.");

# Test whether the database file exists.

ok (-f $test_db, "The database file was created.");

# Remove the generated file.

rm_db ();

my $test_pc_file = File::Spec->catpath (undef, $FindBin::Bin, "KEN_SOME.CSV");

#eval {
    make_database (
        schema_file => $schema_file,
        db_file => $test_db,
        postcode_file => $test_pc_file,
    );
#};

# Test whether an error occurred in creating the database.

ok (! $@, "Make_database did not die.");

# Test whether the database file exists.

ok (-f $test_db, "The database file was created.");

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
