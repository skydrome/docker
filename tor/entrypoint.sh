#!/bin/sh
set -e

# allow entering
[ "$1" = 'sh' ] && exec /bin/ash

[ -f '/tor-data/etc/torrc' ] || {
    echo "cant read torrc"
    exit 1
}

# [ -f /tor-data/pinger.conf ] &&
#     /pinger.sh & || echo "cant read pinger.conf"

# PUID=${PUID=0}
# PGID=${PGID=0}

# echo "==> Performing startup jobs and maintenance tasks"
# chown -hRc "$PUID":"$PGID" /tor-data

echo "==> Starting tor with $(id)"
tor --runasdaemon 0 --torrc-file /tor-data/etc/torrc
