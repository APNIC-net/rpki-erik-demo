package APNIC::RPKI::Utils;

use warnings;
use strict;

use base qw(Exporter);
our @EXPORT_OK = qw(dprint);

sub dprint
{
    my @msgs = @_;

    if ($ENV{'APNIC_DEBUG'}) {
        for my $msg (@msgs) {
            print STDERR "$$: $msg\n";
        }
    }
}

1;
