#!/usr/bin/env bash

source settings.inc

kubectl config set-cluster ${CLUSTER_NAME} \
    --server=https://10.240.0.20 \
    --certificate-authority=${BASEDIR}/../certs/ca.pem