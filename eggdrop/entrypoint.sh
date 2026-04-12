#!/bin/sh
# shellcheck source=/dev/null
set -e

# allow entering
[ "$1" = 'sh' ] && exec /bin/bash

# start as root to set permissions, then drop to unprivileged user
if [ "$(id -u)" = "0" ]; then
    dropbear -Ems \
    -r /etc/dropbear/dropbear_ed25519_host_key \
    -p 0.0.0.0:22 &&
    echo "SSH started on port 22" || echo "SSH failed to start"

    mkdir -p /eggdrop-data/scripts
    chown -R eggdrop /eggdrop-data
    su-exec eggdrop "$0" "$@"
    exit 0
fi

cd /eggdrop

ln -sf /eggdrop-data/scripts ./scripts

[ -f '/eggdrop-data/eggdrop.conf' ] || {
    echo "cant read eggdrop.conf"
    exit 1
}

# if [ -f '/eggdrop-data/.venv/bin/activate' ]; then
#     echo "==> Activating python venv"
#     . .venv/bin/activate
# else
#     echo "==> Creating python venv"
#     uv venv /eggdrop-data/.venv
# fi

echo "==> Starting eggdrop with uid: $(id eggdrop)"
LD_PRELOAD=/usr/lib/libmimalloc-secure.so.2 \
./eggdrop -t /eggdrop-data/eggdrop.conf  #&& tail -qF /tmp/console.log
