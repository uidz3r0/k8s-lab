#!/usr/bin/env bash
set -euo pipefail

ETCDCTL=$(command -v etcdctl)
SNAPSHOT="$1"

sudo ETCDCTL_API=3 "$ETCDCTL" snapshot restore "${SNAPSHOT}" \
  --data-dir=/var/lib/etcd-restored

echo
echo "Restore completed."
echo
echo "Restored data directory:"
echo "/var/lib/etcd-restored"