#!/usr/bin/env bash
set -e

VERSION=v2.4.8
TARGET=linux_amd64
DEST="/opt/bin"

/usr/bin/curl -L https://github.com/containous/traefik/releases/download/${VERSION}/traefik_${VERSION}_${TARGET}.tar.gz >/tmp/traefik.tar.gz
/usr/bin/sudo /usr/bin/tar -C ${DEST} -xzf /tmp/traefik.tar.gz traefik
/usr/bin/sudo mkdir -p /var/lib/traefik/{conf,tls}
/usr/bin/rm -rf /tmp/traefik.tar.gz
