use warnings;
use strict;
use Test::More tests => 4;
use FindBin;
use Geo::Postcodes::JP::Process qw/read_ken_all improve_postcodes/;
use Geo::Postcodes::JP::DB 'make_database';
use utf8;

my $data = "$FindBin::Bin/multiline.csv";
my $postcodes = read_ken_all (
    $data,
);
my $improved = improve_postcodes ($postcodes);
#printf "Number of entries in final version %d\n", scalar @$improved;
ok (@$improved == 1, "Multiline entry to one entry");
my $entry = $improved->[0];
#print "@$entry\n";
#printf "8 is %s\n", $entry->[8];
ok ($entry->[8] =~ /^協和（８８−２、/, "Start of entry OK");
ok ($entry->[8] =~ /１７５２番地）$/, "End of entry OK");

# See Geo-Postcodes-JP-DB.t for explanations of the following
# variables.

my $db_dir = "$FindBin::Bin/../db";

my $test_db = "$FindBin::Bin/multiline.db";

rm_db ();

my $o = make_database (
    db_file => $test_db,
    postcode_file => $data,
);

my $result = $o->lookup_postcode ('0660005');


ok (scalar @$result == 1, "Only one result for test postcode");

$o = undef;

rm_db ();

exit;

# Remove the test database file.


sub rm_db
{
    if (-f $test_db) {
        unlink $test_db or warn $!;
    }
}

