package Table::Readable;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/read_table write_table read_table_hash/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION = '0.06';
use Carp;

# Private routine. This reads the file in and turns it into an array
# containing the lines of the file, without doing any further
# processing work.

sub read_file
{
    my ($file) = @_;
    my @rv;
    open my $in, "<:encoding(utf8)", $file or croak "Error opening '$file': $!";
    while (<$in>) {
	push @rv, $_;
    }
    close $in or croak $!;
    return @rv;
}

sub scalar_to_lines
{
    my ($list_file) = @_;
    my @lines = split /\n/, $list_file;
    for (@lines) {
	$_ .= "\n";
    }
    $lines[-1] =~ s/\n$//;
    return @lines;
}

sub read_table
{
    croak "read_table returns an array" unless wantarray ();
    my ($list_file, %options) = @_;
    # Return value
    my @table;
    my $row = {};
    push @table, $row;
    # This variable controls whether we parse the current entry as a
    # key/value pair on a single line, or one spanning multiple lines.
    my $mode = "single-line";
    my $mkey;

    my @lines;
    if ($options{scalar}) {
	@lines = scalar_to_lines ($list_file);
    }
    else {
        @lines = read_file ($list_file);
    }
    my $count = 0;
    for (@lines) {

        $count++;

	if ($mode ne 'multi-line') {

	    # Detect the first line of a cell of the table whose
	    # information spans several lines of the input file.

	    if (/^%%\s*([^:]+):\s*$/) {
		$mode = "multi-line";
		$mkey = $1;
		next;
	    }
	}

        # Continue to process a table cell whose information spans
        # several lines of the input file.

        if ($mode eq "multi-line") {
            if (/^%%\s*$/) {
                $mode = "single-line";
		if ($row->{$mkey}) {
		    # Strip leading and trailing whitespace
		    $row->{$mkey} =~ s/^\s+|\s+$//g;
		    # Strip leading and trailing slashes
		    $row->{$mkey} =~ s/^\\|\\$//g;
		}
                $mkey = undef;
		next;
            }
	    $row->{$mkey} .= $_;
            next;
        }
        if (/^\s*#.*/) {

            # Skip comments.

            next;
        }
        if (/([^:]+):\s*(.*?)\s*$/) {

            # Key / value pair on a single line.

            my $key = $1;
            my $value = $2;

            # If there are any spaces in the key, substitute them with
            # underscores.

            $key =~ s/\s/_/g;
            if ($row->{$key}) {
                croak "$list_file:$count: duplicate for key $key\n";
            }
	    # Strip leading and trailing slashes
	    $value =~ s/^\\|\\$//g;
            $row->{$key} = $value;
	    next;
        }
        if (/^\s*$/) {

            # A blank line signifies the end of a row.

            if (keys %$row > 0) {
                $row = {};
                push @table, $row;
            }
            next;
        }
	my $file_line = "$list_file:$count:";
	if ($options{scalar}) {
	    $file_line = "$count:";
	}
	warn "$file_line unmatched line '$_'\n";
    }
    # Deal with the case of whitespace at the end of the file.
    my $last_row = $table[-1];
    if (keys %$last_row == 0) {
        pop @table;
    }
    return @table;
}

sub read_table_hash
{
    my ($list_file, $key, %options) = @_;
    my @table = read_table ($list_file, %options);
    my %hash;
    my $i = -1;
    my @order;
    for my $entry (@table) {
	$i++;
	my $ekey = $entry->{$key};
	push @order, $ekey;
	if (! $ekey) {
	    carp "No $key entry for element $i of $list_file";
	    next;
	}
	if ($hash{$ekey}) {
	    carp "Table entries for $key are not unique, duplicate at $i";
	    next;
	}
	$hash{$ekey} = $entry;
    }
    if (wantarray) {
	return \%hash, \@order;
    }
    else {
	return \%hash;
    }
}

sub sort_file
{
    my ($file, $key) = @_;
    my @lines = read_table ($file);
    @lines = sort {
	$a->{$key} cmp $b->{$key}
    } @lines;
    write_table (\@lines, $file);
}

# Maximum length of a single-line entry.

our $maxlen = 75;

sub write_table
{
    my ($list, $file) = @_;
    if (ref $list ne 'ARRAY') {
	carp "First argument to 'write_table' must be array reference";
	return;
    }
    my $n = 0;
    for my $i (@$list) {
	if (ref $i ne 'HASH') {
	    carp "Elements of first argument to 'write_table' must be hash references";
	    return;
	}
	for my $k (keys %$i) {
	    if (ref $i->{$k}) {
		carp "Non-scalar value in key $k of element $n";
		return;
	    }
	}
	$n++;
    }
    my $text = '';
    for (@$list) {
	for my $k (sort keys %$_) {
	    my $v = $_->{$k};
	    if (length ($v) + length ($k) > $maxlen ||
		$v =~ /\n/) {
		$text .=  "%%$k:\n$v\n%%\n";
	    }
	    else {
		$text .=  "$k: $v\n";
	    }
	}
	$text .=  "\n";
    } 
    if ($file) {
	open my $out, ">:encoding(utf8)", $file or croak "Can't open $file for writing: $!";
	print $out $text;
	close $out or croak $!;
    }
    elsif (defined (wantarray ())) {
	return $text;
    }
    else {
	print $text;
    }
}

sub edit_entry
{
    my ($file, $key, %entry) = @_;
    my @table = read_table ($file);
    my $v = $entry{$key};
    if (! $v) {
	croak "Values for entry don't contain an entry for $key";
    }
    for my $entry (@table) {
	if (! $entry->{$key}) {
	    next;
	}
	if ($entry->{$key} ne $entry{$key}) {
	    next;
	}
	print "Found the entry for $key.\n";
    }
}

1;
