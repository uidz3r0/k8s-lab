#!/usr/bin/env bash
set -euo pipefail

echo "Waiting for API Server..."

sleep 20

kubectl get nodes

echo

kubectl get pods -A