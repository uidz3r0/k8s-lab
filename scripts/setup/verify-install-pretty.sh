#!/bin/bash
# ~/k8s-lab/scripts/management/verify-install.sh
# Comprehensive verification script for Kubernetes node setup
# Usage: ./verify-install.sh [--verbose]

set -euo pipefail

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

# Logging functions
log_pass() { echo -e "${GREEN}${CHECKMARK}${NC} $1"; }
log_fail() { echo -e "${RED}${CROSS}${NC} $1"; }
log_warn() { echo -e "${YELLOW}${WARNING}${NC} $1"; }
log_info() { echo -e "${BLUE}${INFO}${NC} $1"; }
log_header() { echo -e "\n${BOLD}${CYAN}═══════ $1 ═══════${NC}"; }
log_subheader() { echo -e "\n${MAGENTA}${ARROW}${NC} ${BOLD}$1${NC}"; }
log_detail() { echo -e "  ${WHITE}$1${NC}"; }
log_success() { echo -e "${GREEN}${BOLD}$1${NC}"; }

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        OS="unknown"
        VERSION="unknown"
    fi
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        log_warn "Running as root - some checks may show root-specific results"
    fi
}

# Header
print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           KUBERNETES NODE VERIFICATION                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    detect_os
    echo -e "${BOLD}System:${NC} $OS $VERSION"
    echo -e "${BOLD}Hostname:${NC} $(hostname)"
    echo -e "${BOLD}Kernel:${NC} $(uname -r)"
    echo -e "${BOLD}Architecture:${NC} $(uname -m)"
    echo ""
}

# Check system basics
check_system() {
    log_header "SYSTEM BASICS"
    
    # Check swap
    log_subheader "Swap Status"
    if swapon --show | grep -q .; then
        log_fail "Swap is ENABLED (should be disabled for Kubernetes)"
        swapon --show
    else
        log_pass "Swap is disabled"
    fi
    
    # Check SELinux (Rocky/RHEL)
    if [[ "$OS" == "rocky" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        log_subheader "SELinux Status"
        if command -v getenforce >/dev/null 2>&1; then
            local selinux_status=$(getenforce)
            if [[ "$selinux_status" == "Permissive" ]] || [[ "$selinux_status" == "Disabled" ]]; then
                log_pass "SELinux: $selinux_status (OK for Kubernetes)"
            else
                log_fail "SELinux: $selinux_status (should be Permissive for Kubernetes)"
            fi
        else
            log_warn "SELinux not installed"
        fi
    fi
    
    # Check time sync
    log_subheader "Time Synchronization"
    if command -v chronyc >/dev/null 2>&1; then
        if chronyc tracking >/dev/null 2>&1; then
            log_pass "Chrony is running"
            chronyc sources -v 2>/dev/null | grep -E "^\^" | head -3 | while read line; do
                log_detail "$line"
            done
        else
            log_fail "Chrony is not tracking properly"
        fi
    elif command -v timedatectl >/dev/null 2>&1; then
        if timedatectl status | grep -q "synchronized: yes"; then
            log_pass "Time is synchronized"
        else
            log_warn "Time may not be synchronized"
        fi
    else
        log_warn "No time sync tool detected"
    fi
    
    # Show current time
    log_detail "Current time: $(date)"
}

# Check kernel modules
check_kernel() {
    log_header "KERNEL MODULES"
    
    local modules=("overlay" "br_netfilter")
    local all_loaded=true
    
    for module in "${modules[@]}"; do
        if lsmod | grep -q "^$module"; then
            log_pass "$module is loaded"
        else
            log_fail "$module is NOT loaded"
            all_loaded=false
        fi
    done
    
    if $all_loaded; then
        log_success "✓ All required kernel modules are loaded"
    else
        log_fail "✗ Missing required kernel modules"
    fi
}

# Check sysctl settings
check_sysctl() {
    log_header "SYSCTL PARAMETERS"
    
    local params=(
        "net.bridge.bridge-nf-call-iptables:1"
        "net.bridge.bridge-nf-call-ip6tables:1"
        "net.ipv4.ip_forward:1"
    )
    
    for param in "${params[@]}"; do
        local key="${param%:*}"
        local expected="${param#*:}"
        local actual=$(sysctl -n "$key" 2>/dev/null || echo "0")
        
        if [[ "$actual" == "$expected" ]]; then
            log_pass "$key = $actual"
        else
            log_fail "$key = $actual (expected $expected)"
        fi
    done
}

# Check container runtime
check_containerd() {
    log_header "CONTAINER RUNTIME"
    
    # Check containerd installation
    log_subheader "Containerd Installation"
    if command -v containerd >/dev/null 2>&1; then
        local version=$(containerd --version 2>/dev/null | head -1)
        log_pass "Containerd is installed: $version"
    else
        log_fail "Containerd is NOT installed"
        return 1
    fi
    
    # Check service status
    log_subheader "Containerd Service"
    if systemctl is-active --quiet containerd; then
        log_pass "Containerd service is running"
        systemctl status containerd --no-pager | head -3 | while read line; do
            log_detail "$line"
        done
    else
        log_fail "Containerd service is NOT running"
        systemctl status containerd --no-pager | head -5
        return 1
    fi
    
    # Check systemd cgroup
    log_subheader "Cgroup Driver"
    if grep -q "SystemdCgroup = true" /etc/containerd/config.toml 2>/dev/null; then
        log_pass "SystemdCgroup is enabled (correct)"
    else
        log_fail "SystemdCgroup is NOT enabled (should be true)"
        log_detail "Check: /etc/containerd/config.toml"
    fi
}

# Check Kubernetes components
check_kubernetes() {
    log_header "KUBERNETES COMPONENTS"
    
    # Check kubeadm
    log_subheader "Kubeadm"
    if command -v kubeadm >/dev/null 2>&1; then
        local version=$(kubeadm version -o short 2>/dev/null || echo "unknown")
        log_pass "Kubeadm: $version"
    else
        log_fail "Kubeadm is NOT installed"
    fi
    
    # Check kubectl
    log_subheader "Kubectl"
    if command -v kubectl >/dev/null 2>&1; then
        local version=$(kubectl version | head -n 1 2>/dev/null || echo "unknown")
        log_pass "Kubectl: $version"
    else
        log_fail "Kubectl is NOT installed"
    fi
    
    # Check kubelet
    log_subheader "Kubelet"
    if command -v kubelet >/dev/null 2>&1; then
        local version=$(kubelet --version 2>/dev/null | head -1)
        log_pass "Kubelet: $version"
        
        # Check service status
        if systemctl is-enabled --quiet kubelet; then
            log_pass "Kubelet is enabled"
        else
            log_warn "Kubelet is NOT enabled"
        fi
        
        # Check if running (may not be if cluster not initialized)
        if systemctl is-active --quiet kubelet; then
            log_pass "Kubelet is running"
        else
            log_warn "Kubelet is not running (normal if cluster not initialized yet)"
        fi
    else
        log_fail "Kubelet is NOT installed"
    fi
}

# Check CRI tools
check_cri() {
    log_header "CRI TOOLS"
    
    # Check crictl
    log_subheader "CRI CLI"
    if command -v crictl >/dev/null 2>&1; then
        log_pass "crictl is installed"
        if crictl info >/dev/null 2>&1; then
            log_pass "crictl can connect to CRI"
            crictl version 2>/dev/null | grep -E "Version" | head -2 | while read line; do
                log_detail "$line"
            done
        else
            log_fail "crictl cannot connect to CRI (containerd not running?)"
        fi
    else
        log_warn "crictl is not installed"
    fi
    
    # Check runc
    log_subheader "OCI Runtime"
    if command -v runc >/dev/null 2>&1; then
        local version=$(runc --version | head -1)
        log_pass "runc is installed: $version"
    else
        log_warn "runc is not installed"
    fi
}

# Check firewall
check_firewall() {
    log_header "FIREWALL STATUS"
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        log_detail "Firewall: firewalld detected"
        if systemctl is-active --quiet firewalld; then
            log_warn "firewalld is RUNNING (may block Kubernetes traffic)"
            log_detail "Run: sudo systemctl stop firewalld && sudo systemctl disable firewalld"
            log_info "At minimum, open the Kubernetes ports:"
            log_detail "  sudo firewall-cmd --permanent --add-port=6443/tcp"
            log_detail "  sudo firewall-cmd --permanent --add-port=2379-2380/tcp"
            log_detail "  sudo firewall-cmd --permanent --add-port=10250/tcp"
            log_detail "  sudo firewall-cmd --permanent --add-port=10251/tcp"
            log_detail "  sudo firewall-cmd --permanent --add-port=10252/tcp"
            log_detail "  sudo firewall-cmd --reload"   
        else
            log_pass "firewalld is not running"
        fi
    elif command -v ufw >/dev/null 2>&1; then
        log_detail "Firewall: UFW detected"
        if systemctl is-active --quiet ufw; then
            log_warn "UFW is RUNNING (may block Kubernetes traffic)"
            log_detail "Run: sudo ufw disable"
            log_info "At minimum, open the Kubernetes ports:"
            log_detail "  sudo ufw allow 6443/tcp"
            log_detail "  sudo ufw allow 2379:2380/tcp"
            log_detail "  sudo ufw allow 10250/tcp"
            log_detail "  sudo ufw allow 10251/tcp"
            log_detail "  sudo ufw allow 10252/tcp"
        else
            log_pass "UFW is not running"
        fi
    elif command -v iptables >/dev/null 2>&1; then
        log_info "Firewall: iptables detected (checking rules...)"
        if sudo iptables -L -n | grep -q "Chain" 2>/dev/null; then
            log_warn "iptables has rules configured"
            log_detail "Check with: sudo iptables -L -n"
            log_info "At minimum, open the Kubernetes ports:"
            log_detail "  sudo iptables -A INPUT -p tcp --dport 6443 -j ACCEPT"
            log_detail "  sudo iptables -A INPUT -p tcp --dport 2379:2380 -j ACCEPT"
            log_detail "  sudo iptables -A INPUT -p tcp --dport 10250 -j ACCEPT"
            log_detail "  sudo iptables -A INPUT -p tcp --dport 10251 -j ACCEPT"
            log_detail "  sudo iptables -A INPUT -p tcp --dport 10252 -j ACCEPT"
        else
            log_pass "iptables: no rules blocking traffic"
        fi
    else
        log_warn "No firewall tool detected"
    fi
    
    # Check required ports (if cluster is running)
    log_subheader "Required Ports"
    local ports=(6443 10250 2379)
    for port in "${ports[@]}"; do
        if ss -tlnp | grep -q ":$port "; then
            log_pass "Port $port is listening"
        else
            log_detail "Port $port is not listening (may not be needed yet)"
        fi
    done
}

# Check cluster connectivity (if kubectl configured)
check_cluster() {
    log_header "CLUSTER CONNECTIVITY"
    
    if kubectl get nodes >/dev/null 2>&1; then
        log_pass "kubectl can connect to cluster"
        
        # Show nodes
        log_subheader "Nodes"
        kubectl get nodes -o wide 2>/dev/null | while read line; do
            log_detail "$line"
        done
        
        # Check control plane
        log_subheader "Control Plane Pods"
        kubectl get pods -n kube-system 2>/dev/null | grep -E "(etcd|apiserver|controller|scheduler)" | while read line; do
            if echo "$line" | grep -q "Running"; then
                log_pass "✓ $line"
            else
                log_warn "⚠ $line"
            fi
        done
        
        # Check storage
        log_subheader "Storage Classes"
        if kubectl get sc 2>/dev/null | grep -q "NAME"; then
            kubectl get sc 2>/dev/null | tail -n +2 | while read line; do
                log_detail "$line"
            done
        else
            log_warn "No storage classes found"
        fi
    else
        if [ -f ~/.kube/config ]; then
            log_fail "kubectl cannot connect to cluster (is cluster running?)"
            log_detail "Check with: kubectl cluster-info"
        else
            log_info "No kubeconfig found (cluster not initialized yet)"
            log_detail "Run: sudo kubeadm init to initialize cluster"
        fi
    fi
}

# Summary
print_summary() {
    log_header "VERIFICATION SUMMARY"
    
    echo ""
    log_success "✅ All checks completed!"
    echo ""
    log_info "Next steps:"
    echo "  • If this is a control plane node:"
    echo "    sudo kubeadm init"
    echo "  • If this is a worker node:"
    echo "    Use the join token from control plane"
    echo "  • For firewall issues:"
    echo "    sudo ufw disable (Ubuntu) or"
    echo "    sudo systemctl stop firewalld (Rocky)"
    echo ""
    log_info "Check cluster status:"
    echo "  kubectl get nodes"
    echo "  kubectl get pods --all-namespaces"
}

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--verbose]"
            echo "  --verbose  Show more detailed output"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_header
    check_root
    check_system
    check_kernel
    check_sysctl
    check_containerd
    check_kubernetes
    check_cri
    check_firewall
    check_cluster
    print_summary
}

# Run main
main