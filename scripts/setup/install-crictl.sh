#!/bin/bash

set -euo pipefail

CRICTL_VERSION="v1.34.0"

echo "Installing crictl ${CRICTL_VERSION}..."

ARCH=$(uname -m)

case "${ARCH}" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

TMPDIR=$(mktemp -d)
cd "${TMPDIR}"

curl -LO "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"

tar -C /usr/bin -xzf "crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"

cat >/etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

if ! command -v crictl >/dev/null 2>&1; then
    echo "ERROR: crictl installation failed."
    exit 1
fi

echo
echo "Installed:"
crictl --version

echo
echo "Configuration:"
cat /etc/crictl.yaml

rm -rf "${TMPDIR}"

echo
echo "Done."