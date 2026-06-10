#!/bin/sh
set -e

# allow entering
[ "$1" = 'sh' ] && exec /bin/ash

# [ -f /tor-data/pinger.conf ] &&
#     /pinger.sh & || echo "cant read pinger.conf"

# PUID=${PUID=0}
# PGID=${PGID=0}

# echo "==> Performing startup jobs and maintenance tasks"
# chown -hRc "$PUID":"$PGID" /tor-data

APP="${APP:-tor}"
echo "==> Starting $APP with $(id)"

if [ "$APP" = 'arti' ]; then
    [ -f '/tor-data/etc/arti.toml' ] || {
        echo "cant read arti.toml"
        exit 1
    }
    cp -f /tor-data/etc/arti.toml /var/lib/tor/arti.toml &&
    arti proxy --config /var/lib/tor/arti.toml

else
    [ -f '/tor-data/etc/torrc' ] || {
        echo "cant read torrc"
        exit 1
    }
    tor --runasdaemon 0 --torrc-file /tor-data/etc/torrc
fi
