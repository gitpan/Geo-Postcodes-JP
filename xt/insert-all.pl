#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
use FindBin;
use lib "$FindBin::Bin/../lib";
}
use Geo::Postcodes::JP::DB qw/make_database test_database/;

my $postcode_file = "$FindBin::Bin/KEN_ALL.CSV";
my $db_file = '/home/ben/projects/Geo-Postcodes-JP/xt/ken_all.db';
my $schema_file = '/home/ben/projects/Geo-Postcodes-JP/db/schema.sql';

if (-f $db_file) {
    unlink $db_file or die $!;
}

make_database (
    db_file => $db_file,
    postcode_file => $postcode_file,
    schema_file => $schema_file,
);

#test_database (
#    $db_file,
#);
