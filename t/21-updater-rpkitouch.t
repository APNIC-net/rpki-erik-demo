#!/usr/bin/perl

use warnings;
use strict;

use APNIC::RPKI::Erik::Updater;
use APNIC::RPKI::Erik::Client;
use APNIC::RPKI::Erik::Server;
use APNIC::RPKI::Erik::Index;
use APNIC::RPKI::Erik::Partition;
use APNIC::RPKI::OpenSSL;

use Cwd qw(cwd);
use DateTime;
use MIME::Base64 qw(encode_base64url);
use File::Temp qw(tempdir);
use File::Slurp qw(read_file write_file);

use Test::More tests => 3;

{
    my $fqdn = "rpki.roa.net";

    my $rtd = tempdir(CLEANUP => 1);
    system("cp -r eg/repo/* $rtd/");
    system("cp -r eg/repo2/* $rtd/$fqdn/rrdp/xTom/");

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
    my $res = system("rpkitouch -c eg/rpki-client.ccr | grep $fqdn > $fn $tail_err");
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

    sub load_index
    {
        my ($path) = @_;
        my $data = read_file($path);
        my $index = APNIC::RPKI::Erik::Index->new();
        $index->decode($data);
        return $index;
    }

    sub load_partition
    {
        my ($path) = @_;
        my $data = read_file($path);
        my $index = APNIC::RPKI::Erik::Partition->new();
        $index->decode($data);
        return $index;
    }

    my $red_index = load_index("$td/.well-known/erik/index/$fqdn");
    my $rt_index  = load_index("$rt_od/erik/index/$fqdn");

    sub convert_hash
    {
        my ($hash) = @_;
        $hash = pack('H*', $hash);
        return encode_base64url($hash);
    }

    my @red_partitions;
    my @rt_partitions;

    for my $red_partition_rec (@{$red_index->partition_list()}) {
        my $hash = $red_partition_rec->{'hash'};
        my $hash_seg = convert_hash($hash);
        my $path = "$td/.well-known/ni/sha-256/$hash_seg"; 
        my $partition = load_partition($path);
        push @red_partitions, $partition;
    }

    for my $rt_partition_rec (@{$rt_index->partition_list()}) {
        my $hash = $rt_partition_rec->{'hash'};
        my $hash_seg = convert_hash($hash);
        my ($f, $s) = ($hash_seg =~ /.*(..)(..)$/);
        my $path = "$rt_od/static/$f/$s/$hash_seg";
        my $partition = load_partition($path);
        push @rt_partitions, $partition;
    }

    for my $ml (map { @{$_->manifest_list()} } (@red_partitions, @rt_partitions)) {
        $ml->{'this_update'} = $ml->{'this_update'}->strftime('%F %T');
    }

    my @red_manifests = map { @{$_->manifest_list()} } @red_partitions;
    my @rt_manifests  = map { @{$_->manifest_list()} } @rt_partitions;

    @red_manifests = sort { $a->{'hash'} cmp $b->{'hash'} } @red_manifests;
    @rt_manifests  = sort { $a->{'hash'} cmp $b->{'hash'} } @rt_manifests;

    is_deeply(\@rt_manifests, \@red_manifests,
        "Manifest generation produced same results");
}

1;
