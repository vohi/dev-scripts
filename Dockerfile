# This provisions a docker image from Ubuntu 12 and installs
# packages for a basic C/C++/Python/Ruby development environment

FROM ubuntu:12.04
MAINTAINER Volker Hilsheimer <volker.hilsheimer@gmail.com>

# 0) set environment variables
# UTF-8 locale for correct decoding of text files in git
# repos
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# 0) All sorts of packages
RUN apt-get update && apt-get install -y \
    git \
    gcc gdb \
    valgrind \
    make \
    automake \
    libtool \
    bison \
    flex \
    byacc \
    libpcre3-dev \
    libssl-dev \
    python \
    vim
