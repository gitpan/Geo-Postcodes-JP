#!/home/ben/software/install/bin/perl
use warnings;
use strict;
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin";
}
use Geo::Postcodes::JP;
use PostCodeFiles qw/$jigyosyo_db/;

my $db_file = $jigyosyo_db;

my $gpj = Geo::Postcodes::JP->new (
    db_file => $db_file,
);
binmode STDOUT, ":encoding(utf8)";
if (@ARGV) {
    for my $postcode (@ARGV) {
        $postcode =~ s/\D//g;
        run ($postcode);
    }
}
else {
    run ('3050054');
    run ('3108610');
    run ('9071892');
}

sub run
{
    my ($postcode) = @_;
    my $addresses = $gpj->postcode_to_address ($postcode);
    if ($addresses) {
        for my $address (@$addresses) {
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
    }
    else {
        print "$postcode not found.\n";
    }

}
