package APNIC::RPKI::Erik::Client;

use warnings;
use strict;

use APNIC::RPKI::Erik::Index;
use APNIC::RPKI::Erik::Partition;
use APNIC::RPKI::Manifest;
use APNIC::RPKI::OpenSSL;
use APNIC::RPKI::Utils qw(dprint);

use Cwd qw(cwd);
use Digest::SHA;
use File::Slurp qw(read_file write_file);
use HTTP::Async;
use LWP::UserAgent;
use MIME::Base64 qw(encode_base64url);

sub new
{
    my ($class, $dir) = @_;

    my $ua = LWP::UserAgent->new();
    my $openssl = APNIC::RPKI::OpenSSL->new();

    my $self = {
        ua      => $ua,
        dir     => $dir,
        openssl => $openssl,
    };
    bless $self, $class;
    return $self;
}

sub hash_to_url
{
    my ($hostname, $hash) = @_;

    $hash = pack('H*', $hash);
    my $hash_segment = encode_base64url($hash);
    my $url = "http://$hostname/.well-known/ni/sha-256/$hash_segment";
    return $url;
}

sub synchronise
{
    my ($self, $hostname, $fqdns) = @_;

    my $ok = 1;

    my $ua      = $self->{'ua'};
    my $dir     = $self->{'dir'};
    my $openssl = $self->{'openssl'};

    my $cwd = cwd();

    my $async = HTTP::Async->new();
    my %id_to_rmd;
    my %relevant_files;

    for my $fqdn (@{$fqdns}) {
        dprint("Requesting index for '$fqdn'");
        my $base_url = "http://$hostname/.well-known";
        my $index_url = "$base_url/erik/index/$fqdn";
        dprint("Submitting fetch for '$index_url'");
        my $id = $async->add(HTTP::Request->new(GET => $index_url));
        $id_to_rmd{$id} = {
            type  => 'fqdn',
            value => $fqdn
        };
    }

    while (my ($res, $id) = $async->wait_for_next_response()) {
        my $rmd = $id_to_rmd{$id};
        my $index_url = $res->request()->uri();
        my ($type, $value) = @{$rmd}{qw(type value)};
        if ($type eq 'fqdn') {
            my $fqdn = $value;
            if (not $res->is_success()) {
                dprint("Unable to fetch index for '$fqdn'");
                $ok = 0;
            } else {
                dprint("Fetched index '$index_url'");

                my $index_content = $res->decoded_content();
                my $index = APNIC::RPKI::Erik::Index->new();
                $index->decode($index_content);

                my $index_scope = $index->index_scope();
                if ($index_scope ne $fqdn) {
                    die "Got incorrect index scope '$index_scope' (expected ".
                        "'$fqdn')";
                }

                my @partition_list = @{$index->partition_list()};
                for my $entry (@partition_list) {
                    my ($size, $hash) =
                        @{$entry}{qw(size hash)};
                    dprint("Processing partition '$hash' with size '$size'");
                    my $partition_url = hash_to_url($hostname, $hash);
                    dprint("Submitting fetch for partition '$partition_url'");

                    my $id = $async->add(HTTP::Request->new(GET => $partition_url));
                    $id_to_rmd{$id} = {
                        type  => 'partition',
                        value => [$fqdn, $hash, $size]
                    };
                }
            }
        } elsif ($type eq 'partition') {
            my ($fqdn, $hash, $size) = @{$value};
            my $partition_url = $res->request()->uri();
            if (not $res->is_success()) {
                dprint("Unable to fetch partition for '$fqdn' ('$hash')");
                $ok = 0;
            } else {
                dprint("Fetched partition '$partition_url'");

                my $partition_content = $res->content();
                my $partition = APNIC::RPKI::Erik::Partition->new();
                $partition->decode($partition_content);
                dprint("Decoded partition '$partition_url'");

                my @manifest_list = @{$partition->manifest_list()};
                for my $entry (@manifest_list) {
                    my ($mftnum, $size, $this_update, $hash, $locations, $aki) =
                        @{$entry}{qw(manifest_number size this_update hash
                                    locations aki)};
                    my @locs = sort @{$locations};
                    my $location = $locs[0];
                    dprint("Processing manifest '$location' (number ".
                        "'$mftnum', size '$size')");
                    my $uri = URI->new($location);
                    my $path = $uri->path();
                    $path =~ s/^\///;
                    $path = $uri->host()."/$path";
                    $relevant_files{$path} = 1;
                    my ($pdir) = ($path =~ /^(.*)\//);
                    my ($file) = ($path =~ /^.*\/(.*)$/);
                    chdir $dir or die $!;
                    system("mkdir -p $pdir");
                    my $get = 0;
                    if (-e $path) {
                        my $digest = Digest::SHA->new(256);
                        $digest->addfile($path);
                        my $content = lc $digest->hexdigest();
                        if ($content ne $hash) {
                            $get = 1;
                        }
                    } else {
                        $get = 1;
                    }
                    if ($get) {
                        dprint("Need to fetch manifest '$location'");
                        my $manifest_url = hash_to_url($hostname, $hash);
                        dprint("Submitting fetch for manifest '$manifest_url'");

                        my $id = $async->add(HTTP::Request->new(GET => $manifest_url));
                        $id_to_rmd{$id} = {
                            type  => 'manifest',
                            value => [$fqdn, $entry, $path, $pdir]
                        };
                    } else {
                        dprint("Do not need to fetch manifest '$location'");

                        my $mdata = $openssl->verify_cms($path);
                        my $manifest = APNIC::RPKI::Manifest->new();
                        $manifest->decode($mdata);
                        my @files = @{$manifest->files() || []};
                        my $file_count = scalar @files;
                        for my $file (@files) {
                            my $filename = $file->{'filename'};
                            my $hash = $file->{'hash'};
                            my $fpath = "$pdir/$filename";
                            $relevant_files{$fpath} = 1;
                        }
                    }
                }
            }
        } elsif ($type eq 'manifest') {
            my ($fqdn, $entry, $path, $pdir) = @{$value};
            my $manifest_url = $res->request()->uri();
            if (not $res->is_success()) {
                dprint("Unable to fetch manifest for '$path'");
                $ok = 0;
            } else {
                write_file($path, $res->decoded_content());
                dprint("Fetched manifest '$manifest_url'");
                dprint("Wrote manifest to path '$path'");

                my $mdata = $openssl->verify_cms($path);
                my $manifest = APNIC::RPKI::Manifest->new();
                $manifest->decode($mdata);
                my @files = @{$manifest->files() || []};
                my $file_count = scalar @files;
                dprint("Manifest file count: '$file_count'");
                for my $file (@files) {
                    my $filename = $file->{'filename'};
                    dprint("Processing file '$filename'");
                    my $hash = $file->{'hash'};
                    my $fpath = "$pdir/$filename";
                    my $get = 0;
                    if (-e $fpath) {
                        my $digest = Digest::SHA->new(256);
                        $digest->addfile($fpath);
                        my $content = lc $digest->hexdigest();
                        if ($content ne $hash) {
                            $get = 1;
                        }
                    } else {
                        $get = 1;
                    }
                    $relevant_files{$fpath} = 1;
                    if ($get) {
                        my $o_url = hash_to_url($hostname, $hash);
                        dprint("Submitting fetch for file '$o_url'");

                        my $id = $async->add(HTTP::Request->new(GET => $o_url));
                        $id_to_rmd{$id} = {
                            type  => 'object',
                            value => [$fqdn, $fpath]
                        };
                    } else {
                        dprint("Do not need to fetch file '$file'");
                    }
                }
            }
        } elsif ($type eq 'object') {
            my ($fqdn, $fpath) = @{$value};
            my $object_url = $res->request()->uri();
            if (not $res->is_success()) {
                dprint("Unable to fetch object for '$fpath'");
                $ok = 0;
            } else {
                write_file($fpath, $res->decoded_content());
                dprint("Fetched file '$object_url'");
                dprint("Wrote file to path '$fpath'");
            }
        }
    }

    if (not $ok) {
        return;
    }

    for my $fqdn (@{$fqdns}) {
	chdir $dir or die $!;
	my @files = `find $fqdn -type f`;
	for my $file (@files) {
	    chomp $file;
	    $file =~ s/^\.\///;
	    if (not $relevant_files{$file}) {
		dprint("Removing '$file' (deleted)");
		unlink $file or die $!;
	    }
	}

	my @empty_dirs = `find $fqdn -type d -empty`;
	for my $empty_dir (@empty_dirs) {
	    chomp $empty_dir;
            dprint("Removing '$empty_dir' (empty directory)");
            rmdir $empty_dir or die $!;
	}
    }

    chdir $cwd;

    return 1;
}

1;
