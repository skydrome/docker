#!/bin/sh
set -eu

TOR_PID=$(pgrep -x tor) || { echo "tor process not found"; exit 1; }
kill -USR1 "$TOR_PID"   || { echo "failed to signal tor" ; exit 1; }

exit 0
