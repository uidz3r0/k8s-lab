#!/usr/bin/env bash

set -e

VIP=10.1.1.15

echo "Current VIP"

ip neigh | grep "$VIP" || true

echo
echo "Testing API"

kubectl get nodes

echo
echo "Locate kube-vip"

kubectl get pods -n kube-system -o wide | grep kube-vip

echo
echo "To test failover"

echo "1. Power off active control plane"
echo "2. Wait 10-20 seconds"
echo "3. Run this script again"