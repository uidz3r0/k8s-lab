#!/usr/bin/env bash
set -euo pipefail

ETCDCTL=$(command -v etcdctl)

LATEST=$(ls -t backups/*.db | head -1)

ETCDCTL_API=3 "$ETCDCTL" snapshot status "${LATEST}" --write-out=table