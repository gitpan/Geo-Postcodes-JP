#!/home/ben/software/install/bin/perl

# This script creates the Perl modules in "lib" from the templates in
# "tmpl".

use warnings;
use strict;

use FindBin;
use Getopt::Long;
use Template;

my $base_dir = "$FindBin::Bin/..";
my $tmpl_dir = "$base_dir/tmpl";
my $lib_dir = "$base_dir/lib";

# This hash is passed to the template toolkit.

my %vars;

# Get configuration information.

# This file contains the configuration information.

my $config_file = "$tmpl_dir/config";

get_configuration (\%vars, $config_file);

# A list of Perl module template files to be processed.

my @pm_templates = (qw/Main.pm Process.pm Update.pm DB.pm/);

# A list of normal files to be processed.

my @templates = (qw/Makefile.PL/);

my %pm_outputs = make_pm_outputs ($vars{config}{base}, @pm_templates);

GetOptions (
    # --clean to clean out the build directories.
    "clean" => \my $clean,
);

if ($clean) {
    clean (\%pm_outputs, \@templates);
    exit;
}

my $tt = Template->new (
    ABSOLUTE => 1,
    INCLUDE_PATH => [$tmpl_dir],
    ENCODING => 'utf8',
);

$vars{ken_all_fields} = get_ken_all_fields ("$FindBin::Bin/ken-all-fields.txt");
$vars{jigyosyo_fields} = get_ken_all_fields ("$FindBin::Bin/jigyosyo-fields.txt");
$vars{address_fields} = get_ken_all_fields ("$FindBin::Bin/address-fields.txt");

# Process the Perl module template files.

for my $template (@pm_templates) {
    my $input_file = make_input_file ($template);
    my $output_file = $pm_outputs{$template};
    if (-f $input_file) {
        # Make it possible to write to the output file.
        chmod 0666, $output_file;
        my $input = read_input_file ($input_file);
        $tt->process (\$input, \%vars, $output_file, {binmode => 'utf8'})
        or die ''. $tt->error ();
        # Make it impossible to edit the output file.
        chmod 0444, $output_file;
    }
    else {
        warn "No $input_file\n";
    }
}

# Process the normal files in order.

for my $template (@templates) {
    my $input_file = "$tmpl_dir/$template.tmpl";
    my $output_file = "$base_dir/$template";
#    print "$input_file $output_file\n";
    my $input = read_input_file ($input_file);
    $tt->process (\$input, \%vars, $output_file, {binmode => 'utf8'})
    or die ''. $tt->error ();
}

# Build the files using the standard Perl build process. Run a test.

# system ("cd $base_dir;perl Makefile.PL; make; make test");

exit;

sub get_configuration
{
    my ($vars_ref, $config_file) = @_;
    open my $input, "<:encoding(utf8)", $config_file or die $!;
    while (<$input>) {
        if (/^(.*?)\s*=\s*(.*?)\s*$/) {
            $vars_ref->{config}->{$1} = $2;
        }
    }
    close $input or die $!;
}

# Clean up all the files.

sub clean
{
    if (-f "$base_dir/Makefile") {
        system ("make -C $base_dir clean > /dev/null");
    }
    rm_file ("$base_dir/Makefile.old");
    my ($pm_outputs, $templates) = @_;
    for my $template (@pm_templates) {
        my $output = $pm_outputs->{$template};
        rm_file ($output);
    }
    for my $template (@$templates) {
        my $output = "$base_dir/$template";
        rm_file ($output);
    }
}

sub make_pm_outputs
{
    my ($sub_dir, @pm_templates) = @_;
    $sub_dir =~ s/::/\//g;
    my %pm_outputs;
    for my $template (@pm_templates) {
        my $input_file = make_input_file ($template);
        my $output_file;
        if ($template eq 'Main.pm') {
            $output_file = "$lib_dir/$sub_dir.pm";
        }
        else {
            $output_file = "$lib_dir/$sub_dir/$template";
        }
        $pm_outputs{$template} = $output_file;
    }
    return %pm_outputs;
}

sub make_input_file
{
    my ($template) = @_;
    return "$tmpl_dir/$template.tmpl";
}

sub rm_file
{
    my ($file) = @_;
    if (-f $file) {
        unlink $file or die $!;
    }
}

sub get_ken_all_fields
{
    my ($file) = @_;
    open my $input, "<:encoding(utf8)", $file
        or die $!;
    my @ken_all_fields;
    my $field = {};
    push @ken_all_fields, $field;
    while (<$input>) {
        if (/^\s*$/) {
            $field = {};
            push @ken_all_fields, $field;
        }
        else {
            if (! $field->{name}) {
                chomp;
                $field->{name} = $_;
            }
            else {
                $field->{description} .= $_;
            }
        }
    }
    # Remove any extra empty entry due to blank lines at the end of the
    # file.
    if (! $field->{name}) {
        pop @ken_all_fields;
    }
    close $input or die $!;
    return \@ken_all_fields;
}

sub read_input_file
{
    my ($input_file) = @_;
    my $line_file = $input_file;
    $line_file =~ s!.*/!!;
    my $input = '';
    open my $in, "<:encoding(utf8)", $input_file or die $!;
    while (<$in>) {
        if (/^#line/) {
            $_ = sprintf ("#line %d \"%s\"\n", $. + 1, $line_file);
        }
        $input .= $_;
    }
    close $in or die $!;
    return $input;
}
