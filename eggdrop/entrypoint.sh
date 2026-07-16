#!/bin/sh
set -e

# allow entering
[ "$1" = 'sh' ] && exec /bin/bash

# start dropbear then drop to unprivileged user
if [ "$(id -u)" -eq 0 ]; then
    dropbear -REms \
        -r /etc/dropbear/dropbear_ed25519_host_key \
        -p 0.0.0.0:22 &&
    echo "SSH started on port 22" || echo "SSH failed to start"

    exec su-exec eggdrop "$0" "$@"
fi

echo "==> Starting eggdrop with user: $(id)"

[ ! -w '/eggdrop-data' ] && {
    echo "cant read/write to volume"
    echo "change owner to uid $(id -u)"
    exit 1
}
[ ! -f '/eggdrop-data/eggdrop.conf' ] && {
    echo "cant read eggdrop.conf"
    exit 1
}

cd /eggdrop
mkdir -p /eggdrop-data/scripts
ln -snf  /eggdrop-data/scripts ./scripts

# if [ -f '/eggdrop-data/.venv/bin/activate' ]; then
#     echo "==> Activating python venv"
#     . .venv/bin/activate
# else
#     echo "==> Creating python venv"
#     uv venv /eggdrop-data/.venv
# fi

exec ./eggdrop -t /eggdrop-data/eggdrop.conf  #&& tail -qF /tmp/console.log
