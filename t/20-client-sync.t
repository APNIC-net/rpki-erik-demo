#!/usr/bin/perl

use warnings;
use strict;

use APNIC::RPKI::Erik::Updater;
use APNIC::RPKI::Erik::Client;
use APNIC::RPKI::Erik::Server;

use Cwd qw(cwd);
use DateTime;
use File::Temp qw(tempdir);
use File::Slurp qw(read_file write_file);

use Test::More tests => 2;

my $pid;

{
    my $cwd = cwd();
    my $td = tempdir(CLEANUP => 1);
    my $updater =
        APNIC::RPKI::Erik::Updater->new(
            "eg/repo", $td
        );
    $updater->synchronise();

    my $server = APNIC::RPKI::Erik::Server->new(0, $td);
    my $port = $server->{'port'};
    if ($pid = fork()) {
    } else {
        $server->run();
        exit(0);
    }

    my $otd = tempdir(CLEANUP => 1);
    my $client = APNIC::RPKI::Erik::Client->new($otd);
    eval {
        $client->synchronise("localhost:$port", ["rpki.roa.net"]);
    };
    my $error = $@;
    ok((not $error),
        "Synchronised remote content successfully");
    diag $error if $error;

    chdir $cwd or die $!;
    my @differences = `diff -r eg/repo $otd`;
    ok((not @differences), "Synchronisation result matches original");
    diag @differences;
}

END {
    if ($pid) {
        kill('TERM', $pid);
    }
}

1;
