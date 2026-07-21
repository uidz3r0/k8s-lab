#!/usr/bin/env bash

#
# check-certificates.sh
#
# Display Kubernetes certificate expiration information.
#

set -euo pipefail

echo
echo "==============================================="
echo " Kubernetes Certificate Expiration Report"
echo "==============================================="
echo

if ! command -v kubeadm >/dev/null 2>&1; then
    echo "ERROR: kubeadm not found."
    exit 1
fi

sudo kubeadm certs check-expiration

echo
echo "PKI Directory:"
echo "--------------"

sudo ls -lh /etc/kubernetes/pki

echo
echo "Certificate Files:"
echo "------------------"

sudo find /etc/kubernetes/pki \
    -type f \
    -name "*.crt"

echo
echo "Done."