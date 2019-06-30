#!/bin/bash

BASEDIR=`dirname $0`
PLATFORM=`uname | tr '[:upper:]' '[:lower:]'`

export CERT_PATH=certs/

rm -rf ${CERT_PATH}
mkdir ${CERT_PATH}
pushd ${CERT_PATH}

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "NO",
      "L": "US",
      "O": "Kubernetes",
      "OU": "Cluster",
      "ST": "US"
    }
  ]
}
EOF

cfssl gencert -initca /data/certs/ca-csr.json | cfssljson -bare ca

mkdir etcd
pushd etcd

cat > etcd-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "NO",
      "L": "US",
      "O": "Kubernetes",
      "OU": "Cluster",
      "ST": "US"
    }
  ]
}
EOF

cfssl gencert \
  -ca=../ca.pem \
  -ca-key=../ca-key.pem \
  -config=../ca-config.json \
  -hostname=10.240.0.10,10.240.0.11,10.240.0.12,etcd1,etcd2,etcd3,127.0.0.1,localhost \
  -profile=kubernetes \
  /data/certs/etcd/etcd-csr.json | cfssljson -bare etcd

popd

mkdir kubernetes
pushd kubernetes

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "NO",
      "L": "US",
      "O": "Kubernetes",
      "OU": "Cluster",
      "ST": "US"
    }
  ]
}
EOF

cfssl gencert \
  -ca=../ca.pem \
  -ca-key=../ca-key.pem \
  -config=../ca-config.json \
  -hostname=10.32.0.1,10.240.0.20,10.240.0.21,10.240.0.22,kubemaster1,kubemaster2,kubemaster3,127.0.0.1,localhost \
  -profile=kubernetes \
  /data/certs/kubernetes/kubernetes-csr.json | cfssljson -bare kubernetes

