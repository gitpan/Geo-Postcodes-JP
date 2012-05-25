#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use FindBin;
use Test::More tests => 4;
use Geo::Postcodes::JP::DB qw/make_database/;
use utf8;

my $test_db = "$FindBin::Bin/bad-addresses.db";

# Delete any existing database file.

rm_db ($test_db);

my $o = make_database (
    db_file => "$test_db",
    postcode_file => "$FindBin::Bin/bad-addresses.csv",
);
    
ok ($o, "Made database from bad addresses");
my $lookup = $o->lookup_postcode ('5400001');
ok ($lookup->[0]->{address_kanji} !~ /（次のビルを除く）/,
    "Bad phrase removed");
my $lookup2 = $o->lookup_postcode ('0010000');
ok ($lookup2->[0]->{address_kanji} !~ /以下に掲載がない場合/,
    "Bad phrase removed");

my $lookup3 = $o->lookup_postcode ('0600042');
ok ($lookup3->[0]->{address_kanji} !~ /丁目/,
    "Bad choume removed");
# Delete the database file.

$o = undef;
rm_db ($test_db);

exit;

sub rm_db
{
    if (-f $test_db) {
        unlink $test_db or warn $!;
    }
}
