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

log_header "CONTAINERD"
containerd --version
systemctl is-active containerd

echo
log_header "KUBELET"
kubelet --version
systemctl is-enabled kubelet

echo
log_header "CRI"
crictl info >/dev/null && crictl version && echo "CRI OK" || echo "crictl not installed"

echo
log_header "OCI Runtime"
if command -v runc >/dev/null 2>&1; then
    runc --version | head -1
else
    echo "runc not installed"
fi

echo
log_header "CGROUP"
grep SystemdCgroup /etc/containerd/config.toml

echo
log_header "SWAP"
swapon --show

echo
log_header "KERNEL MODULES"
lsmod | grep overlay
lsmod | grep br_netfilter

echo
log_header "SYSCTL PARAMETERS"
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward

echo
log_header "VERSIONS"
kubeadm version
kubectl version --client

echo
log_header "FIREWALL"
if command -v firewall-cmd >/dev/null 2>&1; then
    systemctl is-active firewalld
elif command -v ufw >/dev/null 2>&1; then
    systemctl is-active ufw
else
    echo "No supported firewall service detected."
fi
