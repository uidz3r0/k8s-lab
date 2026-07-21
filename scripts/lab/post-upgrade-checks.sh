#!/usr/bin/env bash

#
# verify-upgrade.sh
#

set -euo pipefail

echo
echo "==========================="
echo " Upgrade Verification"
echo "==========================="
echo

kubectl get nodes

echo
kubectl get pods -A

echo
kubectl cluster-info

echo
echo "CoreDNS"

kubectl get deployment \
-n kube-system coredns

echo
echo "Calico"

kubectl get pods \
-n calico-system

echo
echo "kube-vip"

kubectl get pods \
-n kube-system | grep vip || true

echo
echo "Scheduling Test"

kubectl run verify-nginx \
    --image=nginx \
    --restart=Never

kubectl wait \
    pod/verify-nginx \
    --for=condition=Ready \
    --timeout=120s

kubectl delete pod verify-nginx

echo
echo "Upgrade verification completed."