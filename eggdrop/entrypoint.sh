#!/bin/sh
set -e

# allow entering
[ "$1" = 'sh' ] && exec /bin/bash

mkdir -p /eggdrop-data/scripts
chown -R eggdrop /eggdrop-data
su-exec eggdrop ln -sf /eggdrop-data/scripts /eggdrop/scripts

[ -f '/eggdrop-data/eggdrop.conf' ] || {
    echo "cant read eggdrop.conf"
    exit 1
}

cd /eggdrop ||exit 1

dropbear -Ems \
    -r /etc/dropbear/dropbear_ed25519_host_key \
    -p 0.0.0.0:22 &&
    echo "SSH started on port 22" || echo "SSH failed to start"

echo "==> Starting eggdrop with $(id eggdrop)"
LD_PRELOAD=/usr/lib/libmimalloc-secure.so.2 \
su-exec eggdrop \
    ./eggdrop /eggdrop-data/eggdrop.conf && tail -qF /tmp/console.log
