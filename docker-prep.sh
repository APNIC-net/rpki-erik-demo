#!/bin/sh
apt-get update -y
apt-get install -y \
    libhttp-daemon-perl \
    liblist-moreutils-perl \
    libwww-perl \
    libcarp-always-perl \
    libconvert-asn1-perl \
    libclass-accessor-perl \
    libssl-dev \
    libyaml-perl \
    libxml-libxml-perl \
    libio-capture-perl \
    libnet-ip-perl \
    make \
    wget \
    patch \
    gcc \
    rsync \
    libfile-slurp-perl \
    libjson-xs-perl \
    cpanminus \
    jq \
    vim \
    git \
    libdatetime-perl \
    libtls-dev \
    libdigest-sha-perl \
    libexpat1-dev \
    libdevel-nytprof-perl \
    libdevel-cover-perl \
    libnet-ip-xs-perl \
    libtest-most-perl \
    libfile-slurp-perl \
    libio-socket-ip-perl \
    libio-socket-ssl-perl \
    libtest-tcp-perl \
    libnet-async-http-perl \
    libtest-fatal-perl \
    libnet-https-nb-perl \
    libcgi-pm-perl \
    libhttp-server-simple-perl \
    libtest-http-server-simple-perl \
    sudo
cpanm Set::IntSpan Net::CIDR::Set
wget https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_2p/openssl-1.0.2p.tar.gz \
    && tar xf openssl-1.0.2p.tar.gz \
    && cd openssl-1.0.2p \
    && ./config enable-rfc3779 \
    && make \
    && make install
