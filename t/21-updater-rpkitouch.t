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

{
    my $rtd = tempdir(CLEANUP => 1);
    system("cp -r eg/repo/* $rtd/");
    system("cp -r eg/repo2/* $rtd/rpki.roa.net/rrdp/xTom/");

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

    my $eft = File::Temp->new();
    my $efn = $eft->filename();
    $eft->flush();

    my $tail_err = ($ENV{'APNIC_DEBUG'}) ? "" : " 2>/dev/null";
    my $tail_bth = ($ENV{'APNIC_DEBUG'}) ? "" : " >/dev/null 2>&1";

    my $ft = File::Temp->new();
    my $fn = $ft->filename();
    my $res = system("rpkitouch -c eg/rpki-client.ccr | grep rpki.roa.net > $fn $tail_err");
    if ($res != 0) {
        die "rpkitouch command failed";
    }

    my $oft = File::Temp->new();
    my $ofn = $oft->filename();
    $res = system("comm -1 -3 $efn $fn | awk '{ print \$NF }' > $ofn $tail_err");
    if ($res != 0) {
        die "File generation command failed";
    }

    my $rt_od = tempdir(UNLINK => 1);
    chdir("$rtd") or die $!;
    $res = system("sort -R $ofn | xargs rpkitouch -p | xargs rpkitouch -v -d $rt_od $tail_bth");
    if ($res != 0) {
        die "rpkitouch (2) command failed";
    }

    chdir("$cwd/eg") or die $!;
    $res = system("rpkitouch -C -v -d $rt_od rpki-client.ccr $tail_bth");
    if ($res != 0) {
        die "rpkitouch (3) command failed";
    }

    ok(1, "Wrote Erik disk state (rpkitouch) successfully");

    # todo: compare output.
}

1;
