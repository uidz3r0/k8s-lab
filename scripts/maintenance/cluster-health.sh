#!/usr/bin/env bash

set -e

echo "========== Nodes =========="
kubectl get nodes -o wide

echo
echo "========== System Pods =========="
kubectl get pods -A

echo
echo "========== Component Status =========="
kubectl get componentstatuses 2>/dev/null || true

echo
echo "========== Control Plane Pods =========="
kubectl get pods -n kube-system -o wide | grep -E 'etcd|kube-apiserver|controller|scheduler|kube-vip'