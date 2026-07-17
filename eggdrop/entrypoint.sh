#!/bin/sh
# shellcheck disable=SC1091
set -e

# allow entering
[ "$1" = 'sh' ] && exec /bin/bash

# start dropbear then drop to unprivileged user
SSH_PORT=22
if [ "$(id -u)" -eq 0 ]; then
    dropbear -REms \
        -r /etc/dropbear/dropbear_ed25519_host_key \
        -p 0.0.0.0:$SSH_PORT &&
    echo "SSH started on port $SSH_PORT" || echo "SSH failed to start"

    exec su-exec eggdrop "$0" "$@"
fi

cd /eggdrop
ln -sf /eggdrop-data/scripts .

echo "==> Starting eggdrop with user: $(id)"

[ ! -w '/eggdrop-data' ] && {
    echo "cant read/write to volume"
    echo "change owner to uid $(id -u)"
    exit 1
}
[ ! -r '/eggdrop-data/eggdrop.conf' ] && {
    echo "cant read eggdrop.conf"
    exit 1
}
[ ! -e scripts ] && {
    echo "scripts directory is missing"
    exit 1
}

[ -r '/eggdrop-data/.venv/bin/activate' ] && {
    echo "==> Activating python venv"
    . /eggdrop-data/.venv/bin/activate
}

exec ./eggdrop -t /eggdrop-data/eggdrop.conf
