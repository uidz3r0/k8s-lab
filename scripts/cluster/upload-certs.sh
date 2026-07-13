#!/bin/bash
set -e

echo
echo "Uploading Kubernetes certificates..."
echo

kubeadm init phase upload-certs --upload-certs