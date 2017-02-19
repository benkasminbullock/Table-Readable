use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
BEGIN { use_ok('Table::Readable') };
use Table::Readable qw/read_table/;


# Non-existent file

my $bad_file_name = "/holy/non/existant/files/batman";

die if -f $bad_file_name;

eval {
    my $f = read_table ($bad_file_name);
};

like ($@, qr/no such file or directory/i, "Non-existant file error test");

# Bad call with scalar return

eval {
    my $f = read_table ("$Bin/test-table-1.txt");
};

like ($@, qr/returns an array/, "Bad call with scalar return");

my @g = read_table ("$Bin/test-table-1.txt");

ok (@g == 2, "test table row count is OK");
ok ($g[0]->{x} eq "y", "test table data is OK #1");
ok ($g[1]->{a} eq "c", "test table data is OK #2");

my @gg = read_table ("$Bin/test-table-whitespace.txt");

ok (@gg == 2, "Delete empty entry at end");

my @h = read_table ("$Bin/test-table-comments.txt");

ok (@h == 2, "Skip comments");

my @i = read_table ("$Bin/test-multiline.txt");

ok (@i == 1, "Read multiline table");
like ($i[0]->{c}, qr/fruit loops/, "Correctly read multiline table");
unlike ($i[0]->{c}, qr/%%/, "Did not read head of multiline entry");

eval {
my @j = read_table ("$Bin/test-duplicates.txt");
};
like ($@, qr/duplicate for key/i, "Test duplicate detection");

# Check that whitespace immediately before the colon is converted to
# an underscore.

my $t = <<EOF;
this key : value
EOF
my @t = read_table ($t, scalar => 1);
is ($t[0]{'this_key_'}, 'value');

my $u = <<EOF;
novalue:
EOF
my @u = read_table ($u, scalar => 1);
ok (defined $u[0]{novalue});
is ($u[0]{novalue}, '');

my $v = <<EOF;
%%v:
# monkey
%%
EOF
my @v = read_table ($v, scalar => 1);
is ($v[0]{v}, "# monkey");

my $w = <<EOF;
w: walrus # eggman
EOF
my @w = read_table ($w, scalar => 1);
is ($w[0]{w}, "walrus # eggman");


done_testing ();
