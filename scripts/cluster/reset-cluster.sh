#!/bin/bash

echo "Resetting Kubernetes Cluster..."
sudo kubeadm reset -f

sudo rm -rf \
/etc/cni/net.d \        # CNI configuration
/var/lib/cni \          # CNI state
/var/lib/kubelet \      # Kubelet state
~/.kube                 # User kubeconfig

echo "Restarting containerd and kubelet..."
sudo systemctl restart containerd
sudo systemctl restart kubelet

echo
echo "Cluster reset complete."

