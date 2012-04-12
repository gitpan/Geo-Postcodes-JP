use warnings;
use strict;
use Test::More tests => 4;
BEGIN { use_ok('Geo::Postcodes::JP::Process') };
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

exit;

# Local variables:
# mode: perl
# End:
