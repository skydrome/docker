#!/usr/bin/env bash

echo "
docker buildx build . --progress=plain --platform=linux/arm/v7 -t skydrome/znc -t skydrome/znc:armv7
    --load | --push | --no-cache

docker run --rm -it --platform=linux/arm/v7 -v ./data:/znc-data skydrome/znc:${1:-latest} sh
"
