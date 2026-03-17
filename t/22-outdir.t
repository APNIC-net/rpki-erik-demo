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

use Test::More tests => 10;

my $pid;

{
    my $rtd = tempdir(CLEANUP => 1);
    system("cp -r eg/repo/* $rtd/");

    my $cwd = cwd();
    my $td = tempdir(CLEANUP => 1);
    my $updater = APNIC::RPKI::Erik::Updater->new($rtd, $td);
    eval {
        $updater->synchronise();
    };
    my $error = $@;
    ok((not $error),
        "Wrote Erik disk state successfully");
    diag $error if $error;

    my $server = APNIC::RPKI::Erik::Server->new(0, $td);
    my $port = $server->{'port'};
    if ($pid = fork()) {
    } else {
        $server->run();
        exit(0);
    }

    my $otd = tempdir(CLEANUP => 1);
    my $out_td = tempdir(CLEANUP => 1);
    my $client =
        APNIC::RPKI::Erik::Client->new(
            $otd,
            out_dir => $out_td
        );
    eval {
        $client->synchronise("localhost:$port", ["rpki.roa.net"]);
    };
    $error = $@;
    ok((not $error),
        "Synchronised remote content successfully");
    diag $error if $error;

    my @in_otd = `find $otd -type f`;
    is(@in_otd, 0, 'No files written to cache directory');
    my @in_out_td = `find $out_td -type f`;
    ok(@in_out_td, 'Some files written to output directory');
    chdir $out_td or die $!;
    for my $path (@in_out_td) {
        chomp $path;
        unlink $path or die $!;
    }
    chdir $cwd or die $!;
    my $expected_file_count = scalar @in_out_td;

    my $client_writer = APNIC::RPKI::Erik::Client->new($otd);
    eval {
        $client_writer->synchronise("localhost:$port",
                                    ["rpki.roa.net"]);
    };
    $error = $@;
    ok((not $error),
        "Synchronised and wrote remote content successfully");
    diag $error if $error;

    @in_otd = `find $otd -type f`;
    is(@in_otd, $expected_file_count,
        'Files now written to cache directory');

    system("cp -r eg/repo2/61 $rtd/rpki.roa.net/rrdp/xTom/");
    eval {
        $updater->synchronise();
    };
    $error = $@;
    ok((not $error),
        "Updated Erik disk state successfully");
    diag $error if $error;

    eval {
        $client->synchronise("localhost:$port", ["rpki.roa.net"]);
    };
    $error = $@;
    ok((not $error),
        "Resynchronised remote content successfully");
    diag $error if $error;

    @in_otd = `find $otd -type f`;
    is(@in_otd, $expected_file_count,
        'File count in cache directory is the same');
    @in_out_td = `find $out_td -type f`;
    ok(@in_out_td, 'New files written to output directory');
}

END {
    if ($pid) {
        kill('TERM', $pid);
    }
}

1;
