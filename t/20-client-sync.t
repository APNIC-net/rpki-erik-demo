#!/usr/bin/perl

use warnings;
use strict;

use APNIC::RPKI::Erik::Updater;
use APNIC::RPKI::Erik::Client;

use DateTime;
use File::Temp qw(tempdir);
use File::Slurp qw(read_file write_file);

use Test::More tests => 1;

{
    my $td = tempdir(CLEANUP => 1);

    my $updater =
        APNIC::RPKI::Erik::Updater->new(
            "eg/repo", $td
        );
    $updater->synchronise();
    ok(1);
}

1;
