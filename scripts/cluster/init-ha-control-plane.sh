#!/bin/bash

set -euo pipefail

echo "Initializing HA Kubernetes Control Plane..."

sudo kubeadm init \
    --config /k8s-lab/manifests/kubeadm-ha-init.yaml \
    --upload-certs

echo
echo "HA Control Plane initialized successfully."
echo
echo "Next steps:"
echo "  1. Configure kubectl"
echo "     /k8s-lab/scripts/cluster/kubeconfig.sh"
echo
echo "  2. Verify the control plane"
echo "     kubectl get nodes"
echo
echo "  3. Join additional control-plane and worker nodes"