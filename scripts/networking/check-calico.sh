#!/bin/bash

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

log_header "Cluster Nodes"
kubectl get nodes

log_header "System Pods"
kubectl get pods -A

log_header "Calico Pods"
kubectl get pods -n kube-system | grep calico

log_header "CoreDNS"
kubectl get pods -n kube-system -l k8s-app=kube-dns

log_header "Cluster Info"
kubectl cluster-info