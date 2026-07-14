#!/bin/bash

set -euo pipefail

echo "Resetting cluster..."

sudo kubeadm reset -f

sudo systemctl stop kubelet

sudo rm -rf /etc/kubernetes/manifests/*
sudo rm -rf /var/lib/etcd

sudo systemctl start kubelet

echo
echo "Control plane reset complete."