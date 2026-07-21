#!/usr/bin/env bash

#
# cluster-health-report.sh
#

set -euo pipefail

REPORT="cluster-health-$(date +%Y%m%d-%H%M%S).txt"

exec >"$REPORT"

echo "==========================================="
echo " Kubernetes Cluster Health Report"
echo "==========================================="
echo

date

echo
echo "Nodes"
echo "-----"

kubectl get nodes -o wide

echo
echo "Pods"
echo "----"

kubectl get pods -A

echo
echo "Events"
echo "------"

kubectl get events -A \
--sort-by=.metadata.creationTimestamp

echo
echo "Certificate Expiration"
echo "----------------------"

sudo kubeadm certs check-expiration

echo
echo "Cluster Info"
echo "------------"

kubectl cluster-info

echo
echo "Versions"
echo "--------"

kubectl version

echo
echo "Disk"

df -h

echo
echo "Memory"

free -h

echo
echo "Finished"

echo
echo "Report written successfully."
echo "Output file: $REPORT"