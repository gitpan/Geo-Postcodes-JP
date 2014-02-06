#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Geo::Postcodes::JP::DB;
binmode STDOUT, ":utf8";
my $file = '/home/ben/projects/Geo-Postcodes-JP/db/jigyosyo.db';

my $o = Geo::Postcodes::JP::DB->new (
    db_file => $file,
);

my $dbh = $o->{dbh};

my @ken;
my @fields = qw/kanji kana id/;
my $fields_comma = join ',', @fields;

my $get_ken_sql = <<EOF;
select $fields_comma from ken;
EOF

my $get_ken_sth = $dbh->prepare ($get_ken_sql);

my $response = $dbh->selectall_arrayref ($get_ken_sth);
for my $line (@$response) {
    my %values;
    @values{@fields} = @$line;
    # for my $k (keys %values) {
    #     print "$k: $values{$k}; ";
    # }
    # print "\n";
    push @ken, \%values;
}

my $get_city_sql = <<EOF;
select $fields_comma from city where ken_id = ?
EOF

my $get_city_sth = $dbh->prepare ($get_city_sql);

my $get_address_sql = <<EOF;
select $fields_comma from address where city_id = ?
EOF

my $get_address_sth = $dbh->prepare ($get_address_sql);

for my $ken (@ken) {
    $get_city_sth->execute ($ken->{id});
    my $response = $get_city_sth->fetchall_arrayref ();
    for my $line (@$response) {
        my %values;
        @values{@fields} = @$line;
#        for my $k (keys %values) {
#            print "$k: $values{$k}; ";
#        }
#        print "\n";
        $get_address_sth->execute ($values{id});
        my $address_response = $get_address_sth->fetchall_arrayref ();
        for my $address_line (@$address_response) {
            my %address_values;
            @address_values{@fields} = @$address_line;
            print "$ken->{kanji} ";
            print "$values{kanji} ";
            for my $k (keys %address_values) {
                print "$k: $address_values{$k}; ";
            }
            print "\n";
        }
    }
}


