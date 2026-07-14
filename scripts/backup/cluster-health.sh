#!/usr/bin/env bash
set -euo pipefail

echo "Nodes"
kubectl get nodes -o wide

echo
echo "System Pods"
kubectl get pods -n kube-system

echo
echo "Component Status"
kubectl get --raw='/readyz?verbose' | head