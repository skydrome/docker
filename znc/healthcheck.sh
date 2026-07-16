#!/bin/sh
set -eu

PID=$(pgrep -x znc) || { echo "znc process not found"; exit 1; }

for port in \
    $(awk '/^[[:space:]]*Port[[:space:]]*=/{print $3}' /znc-data/configs/znc.conf)
do
    nc -z 127.0.0.1 "$port" || {
        echo "PORT: $port is down"
        _status=1
    }
done

exit $_status
