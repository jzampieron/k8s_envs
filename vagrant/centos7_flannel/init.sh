#!/bin/bash

CFSSL_DOCKER="cfssl/cfssl:1.3.2"

./scripts/download.sh

docker run \
    --rm \
    -v "${PWD}:/data" \
    --workdir=/data \
    --entrypoint=bash \
    ${CFSSL_DOCKER} \
    /data/scripts/ca-config.sh