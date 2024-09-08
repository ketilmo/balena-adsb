#!/usr/bin/env bash
set -e

arch="$(dpkg --print-architecture)"
echo System Architecture: $arch

cd /tmp

bash -c "$(curl -L https://setup.vector.dev)"
apt-get -y install vector
