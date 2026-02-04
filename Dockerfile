FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get install -y build-essential sudo
COPY ./docker-prep.sh .
RUN ./docker-prep.sh
RUN yes | unminimize
COPY . /root/rpki-erik-demo
WORKDIR /root/rpki-erik-demo
RUN sudo cpanm -v -n --installdeps .
RUN sudo make clean || true
RUN perl Makefile.PL && make && sudo make install
CMD /bin/bash
