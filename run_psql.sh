#!/usr/bin/env bash

APP=postgres-postgresql
NAMESPACE=apps

# Get password from:
PW=`kubectl get secret --namespace=apps ${APP} -o yaml|grep password|tr -d ' '|cut -f 2 -d ':'|base64 --decode`

kubectl run --rm -i -t psqltty \
    --image=postgres:11.4-alpine \
    --restart=Never \
    --env="PGPASSWORD=${PW}" \
    -- \
    psql -U postgres -h ${APP}.${NAMESPACE}.svc.cluster.local