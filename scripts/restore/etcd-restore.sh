#!/usr/bin/env bash
set -euo pipefail

SNAPSHOT="$1"

sudo etcdutl snapshot restore "${SNAPSHOT}" \
  --data-dir=/var/lib/etcd-restored

echo
echo "Restore completed."
echo
echo "Restored data directory:"
echo "/var/lib/etcd-restored"