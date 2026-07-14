#!/usr/bin/env bash
set -euo pipefail

LATEST=$(ls -t backups/*.db | head -1)

ETCDCTL_API=3 etcdctl snapshot status "${LATEST}" --write-out=table