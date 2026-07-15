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
echo "Verify cluster"

kubectl get nodes

kubectl get pods -A

echo
echo "Perform maintenance now."

echo
echo "When finished"

echo "kubectl uncordon $NODE"