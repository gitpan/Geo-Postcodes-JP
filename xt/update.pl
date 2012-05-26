#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
};
use PostCodeFiles '$dir';
use Geo::Postcodes::JP::Update 'update_files';

update_files ("$dir/ken_all.zip", "$dir/jigyosyo.zip");
