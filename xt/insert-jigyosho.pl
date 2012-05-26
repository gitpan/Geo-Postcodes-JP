#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin";
}
use Geo::Postcodes::JP::DB;
use PostCodeFiles qw/$jigyosyo_db $no_jigyosyo_db $dir/;

my $jigyosyo_file = "$dir/JIGYOSYO.CSV";
my $db_dir = '/home/ben/projects/Geo-Postcodes-JP/xt';
my $db_orig = $no_jigyosyo_db;
my $db_copy = $jigyosyo_db;

system ("cp $db_orig $db_copy");

my $o = Geo::Postcodes::JP::DB->new (
    db_file => $db_copy,
);
$o->add_jigyosyo (
    db_file => $db_copy,
    jigyosyo_file => $jigyosyo_file,
);
