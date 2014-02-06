#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use lib '../lib';
use Geo::Postcodes::JP::Process qw/read_ken_all
                                   find_duplicates
                                   concatenate_multi_line/;
my $file = '/home/ben/projects/postcodes/data/KEN_ALL.CSV';
my $postcodes = read_ken_all ($file);
my $duplicates = find_duplicates ($postcodes);
binmode STDOUT, ":encoding(utf8)";
concatenate_multi_line ($postcodes, $duplicates);
exit;
for my $k (sort keys %$duplicates) {
    print "$k: \n";#, join (", ", @{$duplicates->{$k}}), "\n";
    for my $x (@{$duplicates->{$k}}) {
        print join (",", @{$postcodes->[$x]}), "\n";
    }
}
