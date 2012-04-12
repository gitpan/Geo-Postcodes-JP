#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
use FindBin;
use lib "$FindBin::Bin/../lib";
}
use Geo::Postcodes::JP;

my $db_file = '/home/ben/projects/Geo-Postcodes-JP/xt/jigyosyo.db';

my $gpj = Geo::Postcodes::JP->new (
    db_file => $db_file,
);
binmode STDOUT, ":encoding(utf8)";
run ('3050054');
run ('3108610');

sub run
{
    my ($postcode) = @_;
    my $address = $gpj->postcode_to_address ($postcode);
    if ($address) {
        print <<'EOF';
  __                       _ 
 / _| ___  _   _ _ __   __| |
| |_ / _ \| | | | '_ \ / _` |
|  _| (_) | |_| | | | | (_| |
|_|  \___/ \__,_|_| |_|\__,_|
                             
EOF
        for my $k (sort keys %$address) {
            print "\"$k\":\"$address->{$k}\"\n";
        }
    }
    else {
        print "$postcode not found.\n";
    }

}
