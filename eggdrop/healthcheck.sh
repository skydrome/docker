#!/bin/sh
# shellcheck disable=SC3001
set -eu

pgrep -x eggdrop || { echo "eggdrop process not found"; exit 1; }

while read -r port; do
    nc -z 127.0.0.1 "$port" || {
        echo "PORT: $port is down"
        _status=1
    }
done < <(awk '/^listen/{gsub(/^\+/,"",$3); print $3}' /eggdrop-data/eggdrop.conf)

exit "${_status:-0}"
