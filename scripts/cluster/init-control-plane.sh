#!/bin/bash

set -e

echo "Initializing Kubernetes Control Plane..."

sudo kubeadm init \
    --config /k8s-lab/manifests/kubeadm-init.yaml

echo
echo "Cluster initialized."
echo
echo "Run:"
echo
echo "scripts/cluster/kubeconfig.sh"