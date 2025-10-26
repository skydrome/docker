#!/bin/bash
set -e
cd '/eggdrop-data/ssl'

set -x
DH="dhparam.pem"
PEM="${1:-eggdrop}-sasl.pem"
KEY="${1:-eggdrop}.key"
CRT="${1:-eggdrop}.crt"

[[ -f "$DH" ]] || {
    # libressl dhparam -out "$DH" 4096
    wget -qO "$DH" https://ssl-config.mozilla.org/ffdhe4096.txt ||
    wget -qO "$DH" https://raw.githubusercontent.com/internetstandards/dhe_groups/main/ffdhe4096.pem
}

[[ -f "$PEM" ]] ||
    libressl ecparam -genkey -name prime256v1 -out "$PEM"

[[ -f "$CRT" ]] ||
    libressl req -x509 -nodes -newkey rsa:4096 -keyout "$KEY" -out "$CRT" -sha256 -days 1825 -subj '/CN=localhost'
