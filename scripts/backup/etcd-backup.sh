#!/usr/bin/env bash
set -euo pipefail

ETCDCTL=$(command -v etcdctl)

BACKUP_DIR="$(pwd)/backups"
mkdir -p "${BACKUP_DIR}"

SNAPSHOT="${BACKUP_DIR}/etcd-$(date +%F-%H%M).db"

sudo ETCDCTL_API=3 "$ETCDCTL" snapshot save "${SNAPSHOT}" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

echo
echo "Snapshot created:"
echo "${SNAPSHOT}"