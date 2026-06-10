#!/usr/bin/env bash

echo "
docker buildx build . --progress=plain --platform=linux/arm/v7 -t skydrome/tor -t skydrome/tor:armv7
    --load | --push | --no-cache

docker run --rm -it --platform=linux/arm/v7 -v ./data:/tor-data -p 9050:9050 -e APP=tor skydrome/tor:${1:-latest} sh
"
