#!/bin/bash
set -e

echo
echo "Generating control plane join command..."
echo

kubeadm token create \
--print-join-command \
--certificate-key $(kubeadm init phase upload-certs --upload-certs | tail -1)