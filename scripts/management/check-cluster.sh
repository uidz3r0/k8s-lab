#!/bin/bash
# Quick cluster health check

echo "=== Cluster Nodes ==="
kubectl get nodes -o wide

echo -e "\n=== Control Plane Pods ==="
kubectl get pods -n kube-system | grep -E "(etcd|apiserver|controller|scheduler)"

echo -e "\n=== Storage Classes ==="
kubectl get sc

echo -e "\n=== Ingress Controllers ==="
kubectl get pods -n ingress-nginx 2>/dev/null || echo "No ingress-nginx namespace"

echo -e "\n=== MetalLB Services ==="
kubectl get pods -n metallb-system 2>/dev/null || echo "No metallb-system namespace"