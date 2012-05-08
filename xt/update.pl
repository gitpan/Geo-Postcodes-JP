#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
};
use Geo::Postcodes::JP::Update 'update_files';

update_files ("$FindBin::Bin/ken_all.zip", "$FindBin::Bin/jigyosyo.zip");
