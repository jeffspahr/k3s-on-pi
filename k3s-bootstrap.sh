#!/bin/bash

#https://blog.alexellis.io/multi-master-ha-kubernetes-in-5-minutes/

set -e

export K8SVERSION=v1.19.1-rc1+k3s1

export NODE_1="$(dig +short k3s-01a.spahr.dev)"
export NODE_2="$(dig +short k3s-01b.spahr.dev)"
export NODE_3="$(dig +short k3s-01c.spahr.dev)"
export USER=jspahr

# The first server starts the cluster
k3sup install \
  --cluster \
  --user $USER \
  --ip $NODE_1 \
  --k3s-version $K8SVERSION

sleep 2

# The second node joins
k3sup join \
  --server \
  --ip $NODE_2 \
  --user $USER \
  --server-user $USER \
  --server-ip $NODE_1 \
  --k3s-version $K8SVERSION


sleep 2

# The third node joins
k3sup join \
  --server \
  --ip $NODE_3 \
  --user $USER \
  --server-user $USER \
  --server-ip $NODE_1 \
  --k3s-version $K8SVERSION

echo "Set your KUBECONFIG"
echo "export KUBECONFIG=`pwd`/kubeconfig"
