#!/usr/bin/perl

use warnings;
use strict;

use APNIC::RPKI::Erik::Index;

use DateTime;
use File::Slurp qw(read_file write_file);
use MIME::Base64 qw(decode_base64);

use Test::More tests => 6;

my $path = "eg/rpki.ripe.net.b64";

{
    my $data_encoded = read_file($path);
    my $data = decode_base64($data_encoded);
    my $index = APNIC::RPKI::Erik::Index->new();
    my $res = $index->decode($data);
    ok($res, "Decoded test index successfully");

    my $index_time = $index->index_time();
    is($index_time->ymd(), "2026-01-08",
        "Decoded index time successfully");
    my @partition_list = @{$index->partition_list()};
    my $count = scalar @partition_list;
    is($count, 256, "Decoded partition list successfully");
}

{
    my $index = APNIC::RPKI::Erik::Index->new();
    $index->index_scope("test.example.net");
    $index->index_time(DateTime->now());
    my @partition_list = (
        { hash => "myhash",
          size => 10 },
        { hash => "myhash",
          size => 10 }
    );
    $index->partition_list(\@partition_list);
    my $enc_data = $index->encode();
    ok($enc_data, "Encoded index successfully");

    my $index2 = APNIC::RPKI::Erik::Index->new();
    my $res = $index2->decode($enc_data);
    ok($res, "Decoded new index successfully");
    @partition_list = @{$index2->partition_list()};
    my $count = scalar @partition_list;
    is($count, 2, "Decoded partition list successfully");
}

1;
