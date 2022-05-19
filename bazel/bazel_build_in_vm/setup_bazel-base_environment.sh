#!/usr/bin/env bash

set -euo pipefail


# This is copied from $MAGMA_ROOT/.devcontainer/bazel-base/Dockerfile and un-dockerfileized


echo "MAGMA_ROOT is $MAGMA_ROOT"

echo "Install general purpose packages" && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        gcc \
        git \
        gnupg2 \
        g++ \
        iproute2 \
        iputils-ping \
        flex \
        libconfig-dev \
        libcurl4-openssl-dev \
        libczmq-dev \
        libgcrypt-dev \
        libgmp3-dev \
        libidn11-dev \
        libsctp1 \
        libsctp-dev \
        libssl-dev \
        libsystemd-dev \
        lld \
        net-tools \
        netbase \
        python3.8 \
        python-is-python3 \
        software-properties-common \
        systemd \
        unzip \
        uuid-dev \
        vim \
        wget \
        zip

apt-get install -y --no-install-recommends \
        libtool=2.4.6-14 && \
    echo "Install Folly dependencies" && \
    apt-get install -y --no-install-recommends \
        libgoogle-glog-dev \
        libgflags-dev \
        libboost-all-dev \
        libevent-dev \
        libdouble-conversion-dev \
        libboost-chrono-dev \
        libiberty-dev && \
    echo "Install libtins and connection tracker dependencies" && \
    apt-get install -y --no-install-recommends \
        libpcap-dev=1.9.1-3 \
        libmnl-dev=1.0.4-2

## Install Fmt (Folly Dep)
git clone https://github.com/fmtlib/fmt.git && \
    ( cd fmt && \
      mkdir _build && \
      cd _build && \
      cmake -DBUILD_SHARED_LIBS=ON -DFMT_TEST=0 .. && \
      make -j"$(nproc)" && \
      make install ) && \
    rm -rf fmt

# Facebook Folly C++ lib
# Note: "Because folly does not provide any ABI compatibility guarantees from
#        commit to commit, we generally recommend building folly as a static library."
# Here we checkout the hash for v2021.02.22.00 (arbitrary recent version)
git clone --depth 1 --branch v2021.02.15.00 https://github.com/facebook/folly && \
    ( cd folly && \
      mkdir _build && \
      cd _build && \
      cmake -DBUILD_SHARED_LIBS=ON .. && \
      make -j"$(nproc)" && \
      make install ) && \
    rm -rf folly

# setup magma artifactories and install magma dependencies
wget -qO - https://artifactory.magmacore.org:443/artifactory/api/gpg/key/public | apt-key add - && \
    add-apt-repository 'deb https://artifactory.magmacore.org/artifactory/debian-test focal-ci main' && \
    add-apt-repository 'deb https://artifactory.magmacore.org/artifactory/debian-test focal-1.7.0 main' && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        bcc-tools \
        liblfds710 \
        oai-asn1c \
        oai-gnutls \
        oai-nettle \
        oai-freediameter

# Update shared library configuration
ldconfig -v

ln -s "$MAGMA_ROOT"/bazel/bazelrcs/vm.bazelrc /etc/bazelrc
