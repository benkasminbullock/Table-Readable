use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Table::Readable ':all';

my $table = [
{
    monkey => 'shines',
    antic => 'banter', 
    buffoonery => 'caper', 
    foolery => 'fooling',
    frolic => 'horseplay',
    mischief => 'nonsense', 
    prank => 'tomfoolery',
},
{
    sonnet => <<EOF,
My love is as a fever longing still,
For that which longer nurseth the disease;
Feeding on that which doth preserve the ill,
The uncertain sickly appetite to please.
My reason, the physician to my love,
Angry that his prescriptions are not kept,
Hath left me, and I desperate now approve
Desire is death, which physic did except.
Past cure I am, now Reason is past care,
And frantic-mad with evermore unrest;
My thoughts and my discourse as madmen's are,
At random from the truth vainly expressed;
   For I have sworn thee fair, and thought thee bright,
   Who art as black as hell, as dark as night.
EOF
},
];
my $wfile = "$Bin/write-test.txt";
write_table ($table, $wfile);
ok (-f $wfile, "Wrote a file");
my @back = read_table ($wfile);
is_deeply ($back[0], $table->[0], "Got back hash keys and values");
my $sonnet = $table->[1]{sonnet};
$sonnet =~ s/^\s+|\s+$//g;
is ($back[1]{sonnet}, $sonnet, "Got back extended text");
unlink ($wfile) or warn "Failed to remove $wfile: $!";
done_testing ();