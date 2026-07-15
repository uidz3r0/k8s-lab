#!/usr/bin/env bash

set -e

NODE=$1

echo "Cordon"

kubectl cordon "$NODE"

echo
echo "Drain"

kubectl drain "$NODE" \
  --ignore-daemonsets \
  --delete-emptydir-data

echo
echo "Maintenance..."

sleep 5

echo
echo "Uncordon"

kubectl uncordon "$NODE"

echo
kubectl get nodes