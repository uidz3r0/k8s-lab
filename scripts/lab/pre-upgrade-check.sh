#!/usr/bin/env bash

#
# pre-upgrade-check.sh
#

set -euo pipefail

echo
echo "================================="
echo " Kubernetes Pre-Upgrade Checklist"
echo "================================="
echo

echo "Nodes"
echo "-----"

kubectl get nodes

echo
echo "Pods"
echo "----"

kubectl get pods -A

echo
echo "Control Plane Pods"
echo "------------------"

kubectl get pods \
-n kube-system

echo
echo "Disk Usage"
echo "----------"

df -h

echo
echo "Certificate Expiration"
echo "----------------------"

sudo kubeadm certs check-expiration

echo
echo "Upgrade Plan"
echo "------------"

sudo kubeadm upgrade plan

echo
echo "Checklist"

cat <<EOF

Before upgrading ensure:

[ ] etcd backup completed

[ ] All nodes Ready

[ ] No Pending Pods

[ ] No CrashLoopBackOff Pods

[ ] Certificate health verified

[ ] Maintenance window approved

EOF