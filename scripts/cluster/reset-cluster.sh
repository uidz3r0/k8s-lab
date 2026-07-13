#!/bin/bash

sudo kubeadm reset -f

sudo rm -rf ~/.kube

sudo rm -rf /etc/cni/net.d

sudo systemctl restart containerd

sudo systemctl restart kubelet

echo
echo "Cluster reset complete."