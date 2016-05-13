=head1 NAME

Table::Readable - read human-editable tabular information from a file

=head1 SYNOPSIS

    use Table::Readable qw/read_table/;
    my @list = read_table ("file.txt");

=head1 DESCRIPTION

Table::Readable enables human beings to create tables of information
which a computer can understand.

=head1 TABLE FORMAT

The table is in the format

    key1: value
    key2: value

    key1: another value
    key2: yet more values

where rows of the table are separated by a blank line, and the columns
of each row are defined by giving the name of the column plus a colon
plus the value.

=head2 Multiline entries

    %%key1:

    value goes here.

    %%

Multiline entries begin and end with two percent characters at the
beginning of the line. Between the two percent characters there may be
any number of blank lines.

=head2 Comments

Lines containing a hash character '#' at the beginning of the line are
ignored.

=head2 Encoding

The file must be encoded in the UTF-8 encoding.

=head1 FUNCTIONS

=cut

package Table::Readable;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/read_table read_list/;
use warnings;
use strict;
our $VERSION = '0.01';
use Carp;
use File::Slurp;

sub open_file
{
    my ($list_file) = @_;
    croak "$list_file not found" unless -f $list_file;
    open my $list, "<:encoding(utf8)", $list_file or die $!;
    return $list;
}

=head2 read_table

    my @table = read_table ("list_file.txt");

Read a table of information from the specified file. Each row of
information is stored as an anonymous hash. 

Each row of the table consists of key/value pairs. The key/value pairs
are given in the form

    key: value

If the key has spaces

    key with spaces: value

then it is turned into C<key_with_spaces> in the anonymous hash.

Rows are separated by a blank line.

So, for example

    row: first
    data: some information

    row: second
    data: more information
    gubbins: guff here

defines two rows, the first one gets a hash reference with entries
C<row> and C<data>, and the second one is a hash reference with
entries C<row> and C<data> and C<gubbins>, each containing the
information on the right of the colon.

If the key begins with two percentage symbols,

    %%key:

then it marks the beginning of a multiline value which continues until
the next line which begins with two percentage symbols. Thus

    %%key:

    this is the value

    %%

assigns "this is the value" to "key".

If the key contains spaces, these are replaced by underscores. For example,

    this key: value

becomes C<this_key> in the output.

Comments can be added to the table using lines with # as the first
character.

The file is assumed to be in the UTF-8 encoding.

=head3 Read from a scalar

    my $table = read_table ($stuff, scalar => 1);

Read from a scalar in C<$stuff>.

=cut

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
        @lines = read_file ($list_file, binmode => 'utf8');
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
