#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/k8s-lab/backups"
mkdir -p "${BACKUP_DIR}"

SNAPSHOT="${BACKUP_DIR}/etcd-$(date +%F-%H%M).db"

sudo etcdctl snapshot save "${SNAPSHOT}" \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

echo
echo "Snapshot created:"
echo "${SNAPSHOT}"