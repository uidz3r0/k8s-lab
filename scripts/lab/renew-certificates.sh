#!/usr/bin/env bash

#
# renew-certificates.sh
#
# Renew kubeadm managed certificates.
#

set -euo pipefail

echo
echo "Renewing Kubernetes certificates..."
echo

sudo kubeadm certs renew all

echo
echo "Restarting kubelet..."
echo

sudo systemctl restart kubelet

echo
echo "Waiting..."
sleep 10

echo
echo "Certificate status:"
echo

sudo kubeadm certs check-expiration

echo
echo "Finished."