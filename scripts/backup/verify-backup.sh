#!/usr/bin/env bash
set -euo pipefail

LATEST=$(ls -t backups/*.db | head -1)

sudo etcdctl snapshot status "${LATEST}" --write-out=table