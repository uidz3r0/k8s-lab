#!/bin/bash

echo
echo "Run the kubeadm join command generated on the control plane."
echo
echo "Example:"
echo
echo "sudo kubeadm join <CONTROL_PLANE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>"
echo