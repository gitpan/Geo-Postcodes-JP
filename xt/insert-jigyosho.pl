#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
}
use Geo::Postcodes::JP::DB;

my $jigyosyo_file = '/home/ben/projects/postcodes/data/jigyosyo.csv';
my $db_dir = '/home/ben/projects/Geo-Postcodes-JP/xt';
my $db_orig = "$db_dir/ken_all.db";
my $db_copy = "$db_dir/jigyosyo.db";

system ("cp $db_orig $db_copy");

my $o = Geo::Postcodes::JP::DB->new (
    db_file => $db_copy,
);
$o->add_jigyosyo (
    db_file => $db_copy,
    jigyosyo_file => $jigyosyo_file,
);
