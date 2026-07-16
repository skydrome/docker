#!/bin/sh
set -eu

PID=$(pgrep -x eggdrop) || { echo "eggdrop process not found"; exit 1; }

for port in \
    $(awk '/^listen/{gsub(/^\+/,"",$3); print $3}' /eggdrop-data/eggdrop.conf)
do
    nc -z 127.0.0.1 "$port" || {
        echo "PORT: $port is down"
        _status=1
    }
done

exit $_status
