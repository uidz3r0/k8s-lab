#!/usr/bin/env bash

#
# upgrade-node.sh
#
# Usage:
#   upgrade-node.sh <node-name>
#

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage:"
    echo "  $0 <node>"
    exit 1
fi

NODE="$1"

echo
echo "Draining $NODE"

kubectl drain "$NODE" \
    --ignore-daemonsets \
    --delete-emptydir-data

echo
echo "------------------------------------------------"
echo "Upgrade kubeadm, kubelet and kubectl manually."
echo "Then run:"
echo
echo "    sudo kubeadm upgrade apply <version>"
echo "or"
echo "    sudo kubeadm upgrade node"
echo
echo "Restart kubelet:"
echo
echo "    sudo systemctl restart kubelet"
echo
read -rp "Press ENTER when complete..."

kubectl uncordon "$NODE"

echo
echo "$NODE returned to service."

kubectl get nodes