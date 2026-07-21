#!/usr/bin/env bash

#
# check-version-skew.sh
#

set -euo pipefail

echo
echo "============================"
echo " Kubernetes Versions"
echo "============================"
echo

echo "kubectl"

kubectl version --client

echo
echo "kubeadm"

kubeadm version

echo
echo "kubelet"

kubelet --version

echo
echo "Cluster"

kubectl get nodes \
-o wide

echo
echo "Version Summary"

kubectl get nodes \
-o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion

echo
echo "Verify versions comply with the Kubernetes Version Skew Policy."