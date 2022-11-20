#!/usr/bin/env bash
set -e

arch="$(dpkg --print-architecture)"
echo System Architecture: $arch

if [ "$arch" = "arm64" ]; then 
	traefik_arch="arm64"
elif [ "$arch" = "amd64" ]; then 
	traefik_arch="amd64"
else 
	traefik_arch="armv6" 
fi

traefik_packet="traefik_v${TRAEFIK_VERSION}_linux_$traefik_arch.tar.gz"

cd /tmp/ && wget --quiet -O traefik.tar.gz "https://github.com/traefik/traefik/releases/download/v${TRAEFIK_VERSION}/$traefik_packet"; 
