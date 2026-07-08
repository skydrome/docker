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
    exec ARTI_FS_DISABLE_PERMISSION_CHECKS=1 \
    arti proxy --config /tor-data/etc/arti.toml

else
    [ -f '/tor-data/etc/torrc' ] || {
        echo "cant read torrc"
        exit 1
    }
    exec tor --runasdaemon 0 --torrc-file /tor-data/etc/torrc
fi
