#!/usr/bin/env bash

source settings.inc || exit 1

USER=admin-${CLUSTER_NAME}

kubectl config set-cluster ${CLUSTER_NAME} \
    --server=https://10.240.0.20:6443 \
    --certificate-authority=${BASEDIR}/../certs/ca.pem

# TODO - do something better with the token.
kubectl config set-credentials ${USER} \
    --token=chAng3m3

kubectl config set-context ${CLUSTER_NAME} \
    --cluster=${CLUSTER_NAME} \
    --user=${USER}