#!/usr/bin/env bash

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Symbols
CHECKMARK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"
ARROW="➜"

log_header() { echo -e "\n${BOLD}${CYAN}═══════ $1 ═══════${NC}"; }
log_subheader() { echo -e "\n${MAGENTA}${ARROW}${NC} ${BOLD}$1${NC}"; }

NODES=$(kubectl get nodes -o name | cut -d/ -f2)

for NODE in $NODES
do
    log_header "Starting Maintenance on $NODE"
    log_subheader "Cordon"

    kubectl cordon "$NODE"

    log_subheader "Drain"

    kubectl drain "$NODE" \
        --ignore-daemonsets \
        --delete-emptydir-data

    log_subheader "Under Maintenance..."

    sleep 3

    kubectl uncordon "$NODE"

done

echo

kubectl get nodes