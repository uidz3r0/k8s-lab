#!/bin/bash

set -euo pipefail

echo "Initializing HA Kubernetes Control Plane..."

sudo kubeadm init \
    --config /k8s-lab/manifests/kubeadm-ha-init.yaml \
    --upload-certs

echo
echo "HA Control Plane initialized."
echo
echo "Next:"
echo "  scripts/cluster/kubeconfig.sh"