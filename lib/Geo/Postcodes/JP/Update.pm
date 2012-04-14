=head1 NAME

Geo::Postcodes::JP::Update - update Japan Post Office postcode data

=cut

package Geo::Postcodes::JP::Update;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/update_files/;

use warnings;
use strict;
our $VERSION = '0.004';


use LWP::UserAgent;

my $ken_all_url =
'http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip';

my $jigyosyo_url = 
'http://www.post.japanpost.jp/zipcode/dl/jigyosyo/zip/jigyosyo.zip';


=head2 update_files

Update the files from the website. This is not finished yet although
it works a bit (you need to edit the code itself to make it work
correctly).

=cut

sub update_files
{
    my ($ken_all_file, $jigyosyo_file) = @_;
    my $agent = LWP::UserAgent->new ();
    download ($agent, $ken_all_url, $ken_all_file);
    download ($agent, $jigyosyo_url, $jigyosyo_file);
    # Update the files.
}

sub download
{
    my ($agent, $url, $file) = @_;
    my $out = $url;
    $out =~ s!.*/!!;
    if (-f $file) {
        # There is a local file, so first compare the dates of the remote
        # file and the local file, and only download the remote file if it
        # is newer.
        print "Local file '$file' exists.\n";
        my $local_date = mdate ($file);
        print "Local date: $local_date.\n";

        my $response = $agent->head($url);
        # Check for errors
        my $remote_date = $response->last_modified;
        print "Remote date: $remote_date.\n";
        if ($local_date < $remote_date) {
            print "Remote file is newer, downloading.\n";
            $response = $agent->get ($url, ":content_file" => $out);
        }
        else {
            print "Remote file is older, not downloading.\n";
        }
    } else {
        # There is no local file, so just download it.
        print "Local file '$file' does not exist.\n";
        my $response = $agent->get ($url, ":content_file" => $out);
    }

}

# Given a file name, return its modification date.

sub mdate
{
    my ($filename) = @_;
    if (!-e $filename) {
        die "reference file '$filename' not found";
    }
    my @stat = stat ($filename);
    if (@stat == 0) {
        die "'stat' failed for '$filename': $@";
    }
    return $stat[9];
}

1;

__END__

=head1 SEE ALSO

L<Number::ZipCode::JP> - validate Japanese zip-codes.

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Geo::Postcodes::JP and associated files are copyright (c) 
2012 Ben Bullock.

You may use, copy, modify and distribute Geo::Postcodes::JP under the
same terms as the Perl programming language itself.

=cut



=cut

# Local variables:
# mode: perl
# End:
