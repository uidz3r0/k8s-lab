#!/bin/bash

echo
echo "Run the command generated on the first control plane."
echo

echo "Example:"

echo "
kubeadm join <CONTROL-PLANE-ENDPOINT>:6443 \
--token <TOKEN> \
--discovery-token-ca-cert-hash sha256:<HASH> \
--control-plane \
--certificate-key <CERT_KEY>
"