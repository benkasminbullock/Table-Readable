=head1 NAME

Table::Readable - read human-readable tabular information from a file

=head1 SYNOPSIS

    use Table::Readable qw/read_table/;
    my @list = read_table ("file.txt");

=head1 DESCRIPTION

=cut

package Table::Readable;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/read_table read_list/;
use warnings;
use strict;
our $VERSION = 0.01;
use Carp;

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

If the key begins with two percentage symbols,

    %%key:

then it marks the beginning of a multiline value which continues until
the next line which begins with two percentage symbols. Thus

    %%key:

    this is the value

    %%

assigns "this is the value" to "key".

Comments can be added to the table using lines with # as the first
character.

The file is assumed to be in the UTF-8 encoding.

=cut

sub read_table
{
    my ($list_file) = @_;
    my $list = open_file ($list_file);
    my @table;
    my $row = {};
    push @table, $row;
    my $mode = "single-line";
    my $mkey;
    while (<$list>) {

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
                $mkey = undef;
            } else {
                $row->{$mkey} .= $_;
            }
            next;
        }
        if (/^\s*#.*/) {

            # Skip comments.

            next;
        } elsif (/([^:]+):\s*(.*?)\s*$/) {

            # Key / value pair on a single line.

            my $key = $1;
            my $value = $2;

            # If there are any spaces in the key, substitute them with
            # underscores.

            $key =~ s/\s/_/g;
            if ($row->{$key}) {
                croak "$list_file:$.: duplicate for key $key\n";
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
            warn "$list_file:$.: unmatched line '$_'\n";
        }
    }
    # Deal with the case of whitespace at the end of the file.
    my $last_row = $table[-1];
    if (keys %$last_row == 0) {
        pop @table;
    }
    close $list or die $!;
    croak "read_table returns an array" unless wantarray ();
    return @table;
}

=head2 read_list

    my @list = read_list ("file.txt");

Read a list of information from a file. Blank lines and lines
beginning with a pound character, #, are ignored.

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
