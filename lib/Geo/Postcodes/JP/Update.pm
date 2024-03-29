=head1 NAME

Geo::Postcodes::JP::Update - update Japan Post Office postcode data

=head1 FUNCTIONS

=cut

package Geo::Postcodes::JP::Update;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/update_files/;

use warnings;
use strict;
our $VERSION = '0.014';

#line 16 "Update.pm.tmpl"

use LWP::UserAgent;

my $ken_all_url =
'http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip';

my $jigyosyo_url = 
'http://www.post.japanpost.jp/zipcode/dl/jigyosyo/zip/jigyosyo.zip';


=head2 update_files

    update_files ('ken_all.zip', 'jigyosyo.zip');

Get or update the two CSV files, KEN_ALL.CSV and JIGYOSYO.CSV from the
Japan Post website.

The two arguments are the file name of the zipped KEN_ALL.CSV file and
the zipped JIGYOSYO.CSV file. If these files exist, the routine tries
to check whether the existing files are newer than the files on the
post office website, and only downloads if the local files are older.

People who are thinking of running this regularly might like to know
that Japan Post usually updates the postcode files on the last day of
the month.

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
    my $response;
    if (-f $file) {
        # There is a local file, so first compare the dates of the remote
        # file and the local file, and only download the remote file if it
        # is newer.
        print "Local file '$file' exists.\n";
        my $local_date = mdate ($file);
        print "Local date: $local_date.\n";

        $response = $agent->head ($url);
        if (! $response->is_success) {
            warn "HEAD request for $url failed: " . $response->status;
            return;
        }
        # Check for errors
        my $remote_date = $response->last_modified;
        print "Remote date: $remote_date.\n";
        if ($local_date < $remote_date) {
            print "Remote file is newer, downloading to $out.\n";
            $response = $agent->get ($url, ":content_file" => $file);
        }
        else {
            print "Remote file is older, not downloading.\n";
        }
    }
    else {
        # There is no local file, so just download it.
        print "Local file '$file' does not exist: putting in $out.\n";
        $response = $agent->get ($url, ":content_file" => $file);
    }
    if (! $response->is_success ()) {
        warn "Download failed: " . $response->status ();
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

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 COPYRIGHT AND LICENSE

Geo::Postcodes::JP and associated files are copyright (c) 
2012 Ben Bullock.

You may use, copy, modify and distribute Geo::Postcodes::JP under the
same terms as the Perl programming language itself.

=cut


#line 114 "Update.pm.tmpl"

# Local variables:
# mode: perl
# End:
