#!/bin/bash

set -e

echo
echo "Installing Calico..."
echo

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/calico.yaml

echo
echo "Waiting for DaemonSet..."
echo

kubectl rollout status daemonset/calico-node -n calico-system --timeout=300s

echo
echo "Calico installed."