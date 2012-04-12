# This test file tests the operation of Geo::Postcodes::JP::Process by
# processing a test file "KEN_SOME.CSV". This test file was made from
# a version of the full file, "KEN_ALL.CSV", by truncating most of the
# lines.

use warnings;
use strict;
use Test::More;
use utf8;
use FindBin;

use Geo::Postcodes::JP::Process 'read_ken_all';

my $data_dir = $FindBin::Bin;
my $postcodes = read_ken_all ("$data_dir/KEN_SOME.CSV");

ok ($postcodes, "Postcode file was read and a defined result was returned.");
ok (ref $postcodes eq 'ARRAY',
    "'Read_ken_all' returned an array reference.");
ok ($postcodes->[3]->[2] eq '0600042',
    "A spot check of the 3rd column of the 4th line was correct.");

done_testing ();

exit;
