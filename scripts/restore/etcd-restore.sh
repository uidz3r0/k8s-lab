#!/usr/bin/env bash
set -euo pipefail

SNAPSHOT="$1"

sudo ETCDCTL_API=3 etcdctl snapshot restore "${SNAPSHOT}" \
  --data-dir=/var/lib/etcd-restored

echo
echo "Restore completed."
echo
echo "Restored data directory:"
echo "/var/lib/etcd-restored"