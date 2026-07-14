#!/usr/bin/env bash
set -euo pipefail

LATEST=$(ls -t /k8s-lab/backups/*.db | head -1)

sudo etcdutl snapshot status "${LATEST}" --write-out=table