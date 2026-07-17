#!/bin/sh
# shellcheck disable=SC3001
set -eu

pgrep -x znc || { echo "znc process not found"; exit 1; }

while read -r port; do
    nc -z 127.0.0.1 "$port" || {
        echo "PORT: $port is down"
        _status=1
    }
done < <(awk '/^[[:space:]]*Port[[:space:]]*=/{print $3}' /znc-data/configs/znc.conf)

exit "${_status:-0}"
