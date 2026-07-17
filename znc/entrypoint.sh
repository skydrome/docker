#!/bin/sh
set -e

# allow entering
[ "$1" = 'sh' ] && exec /bin/ash

echo "==> Starting znc with user: $(id)"

[ ! -w '/znc-data' ] && {
    echo "cant read/write to volume"
    echo "change owner to uid $(id -u)"
    exit 1
}
[ ! -r '/znc-data/configs/znc.conf' ] && {
    echo "cant read configs/znc.conf"
    exit 1
}
[ ! -r '/znc-data/znc.pem' ] && {
    znc -d /znc-data -p
    echo "waiting for pem file to be generated.."
    sleep 5
}

znc --version
exec znc --foreground --datadir /znc-data
