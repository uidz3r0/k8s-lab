#!/bin/bash

set -e

sudo kubeadm reset -f

sudo rm -rf \
/etc/cni/net.d \
/var/lib/cni \
/var/lib/kubelet \
/etc/kubernetes

echo
echo "Worker reset complete."