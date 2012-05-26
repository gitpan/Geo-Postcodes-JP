#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin";
}
use Geo::Postcodes::JP::DB qw/make_database/;
use PostCodeFiles qw/$db_file $dir/;
binmode STDOUT, ":utf8";
my $postcode_file = "$dir/KEN_ALL.CSV";

if (-f $db_file) {
    unlink $db_file or die $!;
}

make_database (
    db_file => $db_file,
    postcode_file => $postcode_file,
);
