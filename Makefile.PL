use strict;
use warnings;
use ExtUtils::MakeMaker;

my $pm = 'lib/Table/Readable.pm';

WriteMakefile (
    NAME => 'Table::Readable',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    PREREQ_PM => {
	'File::Slurp' => 0,
    },
);
