package Table::Readable;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/read_table read_list/;
use warnings;
use strict;
our $VERSION = '0.01';
use Carp;

sub read_file
{
    my ($file) = @_;
    my @rv;
    open my $in, "<:encoding(utf8)", $file or die $!;
    while (<$in>) {
	push @rv, $_;
    }
    close $in or die $!;
    return @rv;
}

sub open_file
{
    my ($list_file) = @_;
    croak "$list_file not found" unless -f $list_file;
    open my $list, "<:encoding(utf8)", $list_file or die $!;
    return $list;
}

sub read_table
{
    my ($list_file, %options) = @_;
    my @table;
    my $row = {};
    push @table, $row;
    my $mode = "single-line";
    my $mkey;

    my @lines;
    if ($options{scalar}) {
        @lines = split /\n/, $list_file;
	for (@lines) {
	    $_ .= "\n";
	}
	$lines[-1] =~ s/\n$//;
    }
    else {
        @lines = read_file ($list_file);
    }
    my $count = 0;
    for (@lines) {

        $count++;

        # Detect the first line of a cell of the table whose
        # information spans several lines of the input file.

        if (/^%%\s*([^:]+):\s*$/) {
            $mode = "multi-line";
            $mkey = $1;
            next;
        }

        # Continue to process a table cell whose information spans
        # several lines of the input file.

        if ($mode eq "multi-line") {
            if (/^%%\s*$/) {
                $mode = "single-line";
		if ($row->{$mkey}) {
		    # Strip leading and trailing whitespace
		    $row->{$mkey} =~ s/^\s+|\s+$//g;
		}
                $mkey = undef;
            }
            else {
                $row->{$mkey} .= $_;
            }
            next;
        }
        if (/^\s*#.*/) {

            # Skip comments.

            next;
        }
        elsif (/([^:]+):\s*(.*?)\s*$/) {

            # Key / value pair on a single line.

            my $key = $1;
            my $value = $2;

            # If there are any spaces in the key, substitute them with
            # underscores.

            $key =~ s/\s/_/g;
            if ($row->{$key}) {
                croak "$list_file:$count: duplicate for key $key\n";
            }
            $row->{$key} = $value;
        }
        elsif (/^\s*$/) {

            # A blank line signifies the end of a row.

            if (keys %$row > 0) {
                $row = {};
                push @table, $row;
            }
            next;
        }
        else {
            warn "$list_file:$count: unmatched line '$_'\n";
        }
    }
    # Deal with the case of whitespace at the end of the file.
    my $last_row = $table[-1];
    if (keys %$last_row == 0) {
        pop @table;
    }
    croak "read_table returns an array" unless wantarray ();
    return @table;
}

=head2 read_list

    my @list = read_list ("file.txt");

Read a list of information from a file. Blank lines and lines
beginning with a pound character, #, are ignored.

The file is assumed to be in the UTF-8 encoding.

=cut

sub read_list
{
    my ($list_file) = @_;
    my $list = open_file ($list_file);
    my @table;
    while (<$list>) {
        next if /^\s*$/;
        next if /^\s*#.*$/;
        chomp;
        push @table, $_;
    }
    close $list or die $!;
    return @table;
}

1;
