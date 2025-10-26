#!/bin/sh
set -e

#if [ "$(id -u)" = '0' ]; then
#    chown -R znc:znc "$DATADIR" || exit 1
#    chmod 700 "$DATADIR" || exit 2
#    exec su-exec znc:znc /entrypoint.sh "$@"
#fi

# allow entering
[ "$1" = 'sh' ] && exec /bin/ash

[ -f '/znc-data/configs/znc.conf' ] || {
    echo "cant read configs/znc.conf"
    exit 1
}

if [ ! -f '/znc-data/znc.pem' ]; then
    znc -d /znc-data -p
    echo "waiting for pem file to be generated.."
    sleep 5
fi

echo "==> Starting znc with $(id)"
znc --version

LD_PRELOAD=/usr/lib/libmimalloc-secure.so.2 \
znc --foreground --datadir /znc-data
