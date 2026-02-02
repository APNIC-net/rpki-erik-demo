use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Config;

my $output = WriteMakefile(
    NAME           => 'APNIC::RPKI::Manifest',
    AUTHOR         => 'Software <software@apnic.net>',
    LICENSE        => 'bsd',
    VERSION_FROM   => 'lib/APNIC/RPKI/Manifest.pm',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/APNIC-net/rpki-erik-demo'
        }
    },
    EXE_FILES      => [],
    PREREQ_PM      => { 'Test::More'      => 0,
                        'File::Slurp'     => 0,
                        'IO::Socket'      => 0,
                        'JSON::XS'        => 0,
                        'Net::IP::XS'     => 0,
                        'IO::Select'      => 0,
                        'IO::Socket::SSL' => 0,
                        'Net::EmptyPort'  => 0, }
);

1;
