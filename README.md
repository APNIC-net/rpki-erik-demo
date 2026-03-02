## rpki-erik-demo

[![Build Status](https://github.com/APNIC-net/rpki-erik-demo/actions/workflows/build.yml/badge.svg)](https://github.com/APNIC-net/rpki-erik-demo/actions)

A proof-of-concept for the Erik synchronisation protocol.

### Build

    $ docker build -t apnic/rpki-erik-demo .

### Usage

    $ docker run -it apnic/rpki-erik-demo /bin/bash

### Tests

    $ docker run -it apnic/rpki-erik-demo make test

### Client

    $ mkdir /tmp/repo
    $ erik-client --cache-dir /tmp/repo --server relay.rpki-servers.org --fqdn rpki.roa.net
    $ find /tmp/repo -type f | head -n 5
    /tmp/repo/rpki.roa.net/rrdp/xTom/61/5577EED829CD0AC31399054DE74453562390C62F.crl
    /tmp/repo/rpki.roa.net/rrdp/xTom/61/5577EED829CD0AC31399054DE74453562390C62F.mft
    /tmp/repo/rpki.roa.net/rrdp/xTom/41/326130623a323534323a3530303a3a2f34302d3438203d3e20313937373330.roa
    /tmp/repo/rpki.roa.net/rrdp/xTom/41/326130623a323534323a3130303a3a2f34302d3438203d3e20313334363636.roa
    /tmp/repo/rpki.roa.net/rrdp/xTom/41/326130343a366630303a3a2f33322d3438203d3e2033323134.roa

### Server

    $ mkdir /tmp/httpd-dir
    $ erik-updater --cache-dir /root/rpki-erik-demo/eg/repo --httpd-dir /tmp/httpd-dir
    $ erik-server --port 8080 --httpd-dir /tmp/httpd-dir &
    $ mkdir /tmp/repo
    $ erik-client --cache-dir /tmp/repo --server localhost:8080 --fqdn rpki.roa.net
    $ find /tmp/repo -type f | head -n 5
    /tmp/repo/rpki.roa.net/rrdp/xTom/61/5577EED829CD0AC31399054DE74453562390C62F.crl
    /tmp/repo/rpki.roa.net/rrdp/xTom/61/5577EED829CD0AC31399054DE74453562390C62F.mft
    /tmp/repo/rpki.roa.net/rrdp/xTom/41/326130623a323534323a3530303a3a2f34302d3438203d3e20313937373330.roa
    /tmp/repo/rpki.roa.net/rrdp/xTom/41/326130623a323534323a3130303a3a2f34302d3438203d3e20313334363636.roa
    /tmp/repo/rpki.roa.net/rrdp/xTom/41/326130343a366630303a3a2f33322d3438203d3e2033323134.roa

### Other

When the environment variable `APNIC_DEBUG` is set, debug messages
will be printed to standard error.

### License

See [LICENSE](./LICENSE).
