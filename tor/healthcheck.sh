#!/bin/sh
set -eu

PID=$(pgrep -x tor) || { echo "tor process not found"; exit 1; }
kill -USR1 "$PID"   || { echo "failed to signal tor" ; exit 1; }

exit 0
