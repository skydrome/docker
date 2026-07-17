#!/usr/bin/env bash

echo "
docker buildx build . --progress=plain --platform=linux/arm/v7 -t skydrome/eggdrop -t skydrome/eggdrop:armv7
    --load | --push | --no-cache

docker run --rm -it --platform=linux/arm/v7 -v ./data:/eggdrop-data -p 22:22 skydrome/eggdrop:${1:-latest} sh
"
