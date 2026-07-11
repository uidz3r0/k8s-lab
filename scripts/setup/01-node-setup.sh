#!/bin/bash
# ~/k8s-lab/scripts/setup/01-node-setup.sh
# Unified node setup for Kubernetes (Rocky Linux & Ubuntu)
# Usage: ./01-node-setup.sh [--version 1.34]

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default Kubernetes version
K8S_VERSION="${1:-1.34}"

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        log_info "Detected OS: $OS $VERSION"
    else
        log_error "Cannot detect OS"
        exit 1
    fi
}

# Disable swap
disable_swap() {
    log_info "Disabling swap (required for Kubernetes)..."
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    log_info "Swap disabled"
}

exit 0

# Install container runtime (containerd)
install_containerd() {
    log_info "Installing containerd..."
    
    case $OS in
        ubuntu)
            sudo apt-get update
            sudo apt-get install -y containerd
            ;;
        rocky|rhel|centos)
            sudo dnf install -y dnf-utils
            sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
            sudo dnf install -y containerd.io
            ;;
        *)
            log_error "Unsupported OS for containerd installation"
            exit 1
            ;;
    esac
    
    # Configure containerd
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
    
    # Enable systemd cgroup driver (better for Kubernetes)
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    
    sudo systemctl enable containerd
    sudo systemctl restart containerd
    log_info "Containerd installed and configured"
}

# Install Kubernetes components
install_kubernetes() {
    log_info "Installing Kubernetes v$K8S_VERSION components..."
    
    case $OS in
        ubuntu)
            # Install prerequisites
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gpg
            
            # Add Kubernetes repository
            local K8S_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/"
            log_info "Adding Kubernetes repository: $K8S_REPO"
            
            curl -fsSL "${K8S_REPO}/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
            
            echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] ${K8S_REPO} /" \
                | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
            
            sudo apt-get update
            sudo apt-get install -y kubelet kubeadm kubectl
            sudo apt-mark hold kubelet kubeadm kubectl
            ;;
            
        rocky|rhel|centos)
            # Add Kubernetes repository
            local K8S_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/rpm/"
            log_info "Adding Kubernetes repository: $K8S_REPO"
            
            cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=${K8S_REPO}
enabled=1
gpgcheck=1
gpgkey=${K8S_REPO}/repodata/repomd.xml.key
EOF
            
            sudo dnf makecache
            sudo dnf install -y kubelet kubeadm kubectl
            sudo dnf mark hold kubelet kubeadm kubectl
            ;;
            
        *)
            log_error "Unsupported OS for Kubernetes installation"
            exit 1
            ;;
    esac
    
    # Enable kubelet (but don't start yet - needs cluster config)
    sudo systemctl enable kubelet
    log_info "Kubernetes components installed"
}

# Install common tools
install_tools() {
    log_info "Installing common tools..."
    
    case $OS in
        ubuntu)
            sudo apt-get install -y \
                vim \
                curl \
                wget \
                net-tools \
                telnet \
                htop \
                jq \
                git
            ;;
        rocky|rhel|centos)
            sudo dnf install -y \
                vim \
                curl \
                wget \
                net-tools \
                telnet \
                htop \
                jq \
                git
            ;;
    esac
    
    # Install kubectl bash completion
    echo "source <(kubectl completion bash)" >> ~/.bashrc
    echo "alias k=kubectl" >> ~/.bashrc
    echo "complete -o default -F __start_kubectl k" >> ~/.bashrc
    
    log_info "Common tools installed"
}

# Configure kernel modules for Kubernetes
configure_kernel() {
    log_info "Loading kernel modules..."
    
    # Load overlay and br_netfilter modules
    sudo modprobe overlay
    sudo modprobe br_netfilter
    
    # Persist modules
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
    
    # Configure sysctl parameters
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    
    sudo sysctl --system
    log_info "Kernel modules configured"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then 
        log_error "Please run as a regular user with sudo privileges, not as root"
        exit 1
    fi
    
    # Check for Internet connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_warn "No internet connectivity detected. Some steps may fail."
    fi
    
    # Check DNS
    if ! nslookup google.com &> /dev/null; then
        log_warn "DNS resolution might be problematic."
    fi
    
    log_info "Prerequisites check completed"
}

# Main execution
main() {
    log_info "Starting Kubernetes node setup (v$K8S_VERSION)..."
    
    check_prerequisites
    detect_os
    
    case $OS in
        ubuntu)
            log_info "Configuring Ubuntu node..."
            ;;
        rocky|rhel|centos)
            log_info "Configuring Rocky Linux node..."
            ;;
        *)
            log_error "Unsupported OS: $OS"
            log_error "This script supports: Ubuntu, Rocky Linux, RHEL, CentOS"
            exit 1
            ;;
    esac
    
    disable_swap
    configure_kernel
    install_containerd
    install_kubernetes
    install_tools
    
    log_info "✅ Node setup completed successfully!"
    log_info "📝 Next steps:"
    log_info "  1. For control plane: run kubeadm init"
    log_info "  2. For worker nodes: join using the token from control plane"
    log_info "  3. Configure firewall rules if needed"
    
    # Show what was installed
    echo ""
    log_info "Installed versions:"
    echo "  - containerd: $(containerd --version 2>/dev/null || echo 'N/A')"
    echo "  - kubeadm: $(kubeadm version -o short 2>/dev/null || echo 'N/A')"
    echo "  - kubectl: $(kubectl version --client -o short 2>/dev/null || echo 'N/A')"
    echo "  - kubelet: $(kubelet --version 2>/dev/null || echo 'N/A')"
}

# Show usage
show_usage() {
    echo "Usage: $0 [--version K8S_VERSION]"
    echo "  --version  Kubernetes version (default: 1.34)"
    echo "  --help     Show this help"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            K8S_VERSION="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Run main
main