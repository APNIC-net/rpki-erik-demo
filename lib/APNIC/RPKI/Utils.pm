package APNIC::RPKI::Utils;

use warnings;
use strict;

use base qw(Exporter);
our @EXPORT_OK = qw(dprint
                    system_ad);

sub dprint
{
    my @msgs = @_;

    if ($ENV{'APNIC_DEBUG'}) {
        for my $msg (@msgs) {
            print STDERR "$$: $msg\n";
        }
    }
}

sub system_ad
{
    my ($cmd, $debug) = @_;

    my $res = system($cmd.($debug ? "" : " >/dev/null 2>&1"));
    if ($res != 0) {
        die "Command execution failed.\n";
    }

    return 1;
}

1;
