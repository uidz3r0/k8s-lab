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

# Run sudo commands only when needed
run_privileged() {
    if [ "$EUID" -eq 0 ]; then
        "$@"  # Already root, run directly
    else
        sudo "$@"  # Use sudo
    fi
}

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then 
        log_error "Please run as a regular user with sudo privileges, not as root"
        log_error "   Correct: ./node-setup.sh"
        log_error "   Wrong:   sudo su - && ./node-setup.sh"
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

# Configure SSH (ensure it's enabled and running)
configure_ssh() {
    log_info "Configuring SSH..."
    
    case $OS in
        ubuntu)
            run_privileged apt-get update
            run_privileged apt-get install -y openssh-server
            ;;
        rocky|rhel|centos)
            run_privileged dnf install -y openssh-server
            ;;
    esac
    
    # Ensure SSH is enabled and running
    run_privileged systemctl enable sshd
    run_privileged systemctl start sshd
    
    # Secure SSH configuration
    run_privileged sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    run_privileged sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    run_privileged sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # Restart SSH to apply changes
    run_privileged systemctl restart sshd
    
    log_info "SSH configured and running"
}

# Configure chrony for time synchronization
configure_chrony() {
    log_info "Configuring time synchronization (chrony)..."
    
    case $OS in
        ubuntu)
            run_privileged apt-get install -y chrony
            ;;
        rocky|rhel|centos)
            run_privileged dnf install -y chrony
            ;;
    esac
    
    # Configure chrony with reliable NTP servers
    cat <<EOF | run_privileged tee /etc/chrony.conf
# Use public NTP servers
pool time.google.com       iburst minpoll 6 maxpoll 10
pool ntp.ubuntu.com        iburst minpoll 6 maxpoll 10
pool 0.pool.ntp.org        iburst minpoll 6 maxpoll 10

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# Enable hardware timestamping on all interfaces that support it.
#hwtimestamp *

# Increase the minimum number of selectable sources required to adjust
# the system clock.
#minsources 2

# Allow NTP client access from local network.
#allow 192.168.0.0/16

# Serve time even if not synchronized to a time source.
#local stratum 10
EOF
    
    # Enable and start chrony
    run_privileged systemctl enable chronyd
    run_privileged systemctl restart chronyd
    
    # Wait a moment for chrony to sync
    sleep 2
    
    log_info "Time synchronization configured"
    
    # Show time status
    if command -v chronyc &> /dev/null; then
        log_info "Chrony sources:"
        run_privileged chronyc sources -v
    fi
}

# Configure SELinux for Rocky Linux
configure_selinux() {
    if [[ "$OS" == "rocky" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        log_info "Configuring SELinux for Kubernetes compatibility..."
        
        # Check if SELinux is installed
        if command -v getenforce &> /dev/null; then
            local SELINUX_STATUS=$(getenforce)
            log_info "Current SELinux status: $SELINUX_STATUS"
            
            # Set SELinux to permissive mode (recommended for Kubernetes)
            if [[ "$SELINUX_STATUS" != "Permissive" ]]; then
                log_info "Setting SELinux to permissive mode..."
                run_privileged setenforce 0
                
                # Make it persistent
                run_privileged sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
                run_privileged sed -i 's/^SELINUX=disabled/SELINUX=permissive/' /etc/selinux/config
                
                log_info "SELinux set to permissive mode (persistent)"
            else
                log_info "SELinux already in permissive mode"
            fi
        else
            log_warn "SELinux not installed or not detected"
        fi
    else
        log_info "SELinux configuration not needed for $OS"
    fi
}

# Disable swap
disable_swap() {
    log_info "Disabling swap (required for Kubernetes)..."
    run_privileged swapoff -a
    run_privileged sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    log_info "Swap disabled"
}

# Configure kernel modules for Kubernetes
configure_kernel() {
    log_info "Loading kernel modules..."
    
    # Load overlay and br_netfilter modules
    run_privileged modprobe overlay
    run_privileged modprobe br_netfilter
    
    # Persist modules
    cat <<EOF | run_privileged tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
    
    # Configure sysctl parameters
    cat <<EOF | run_privileged tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    
    run_privileged sysctl --system
    log_info "Kernel modules configured"
}

# Install container runtime (containerd)
install_containerd() {
    if ! command -v containerd >/dev/null 2>&1; then
        log_info "Installing containerd..."
        case $OS in
            ubuntu)
                run_privileged apt update
                run_privileged apt install -y containerd
                ;;
            rocky|rhel|centos)
                run_privileged dnf install -y epel-release
                run_privileged dnf install -y dnf-utils
                run_privileged dnf install -y containerd runc
                ;;
            *)
                log_error "Unsupported OS for containerd installation"
                exit 1
                ;;
        esac
    else
        log_info "containerd already installed."
    fi
    
    echo "Generating containerd default configuration..."
    run_privileged mkdir -p /etc/containerd
    run_privileged containerd config default | run_privileged tee /etc/containerd/config.toml > /dev/null
    
    echo "Enabling SystemdCgroup..."
    run_privileged sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
    
    echo "Starting containerd..."
    run_privileged systemctl enable containerd
    run_privileged systemctl restart containerd
    log_info "Containerd installed and configured"
}

# Install Kubernetes components
install_kubernetes() {
    log_info "Installing Kubernetes v$K8S_VERSION components..."
    
    case $OS in
        ubuntu)
            # Install prerequisites
            run_privileged apt-get update
            run_privileged apt-get install -y apt-transport-https ca-certificates curl gpg
            
            # Create keyrings directory if it doesn't exist
            run_privileged mkdir -p /etc/apt/keyrings
            
            # Add Kubernetes repository
            local K8S_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/"
            log_info "Adding Kubernetes repository: $K8S_REPO"
            
            curl -fsSL "${K8S_REPO}/Release.key" | run_privileged gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
            
            echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] ${K8S_REPO} /" \
                | run_privileged tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
            
            run_privileged apt-get update
            run_privileged apt-get install -y kubelet kubeadm kubectl
            run_privileged apt-mark hold kubelet kubeadm kubectl
            ;;
            
        rocky|rhel|centos)
            # Add Kubernetes repository
            local K8S_REPO="https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/rpm/"
            log_info "Adding Kubernetes repository: $K8S_REPO"
            
            cat <<EOF | run_privileged tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=${K8S_REPO}
enabled=1
gpgcheck=1
gpgkey=${K8S_REPO}/repodata/repomd.xml.key
EOF
            
            run_privileged dnf makecache
            run_privileged dnf install -y kubelet kubeadm kubectl
            
            log_info "Installing versionlock plugin..."
            run_privileged dnf install -y 'dnf-command(versionlock)'
            
            log_info "Locking Kubernetes package versions..."
            run_privileged dnf versionlock add kubelet kubeadm kubectl
            ;;
            
        *)
            log_error "Unsupported OS for Kubernetes installation"
            exit 1
            ;;
    esac
    
    # Enable kubelet (but don't start yet - needs cluster config)
    run_privileged systemctl enable kubelet
    log_info "Kubernetes components installed"
}

# Install common tools
install_tools() {
    log_info "Installing common tools..."
    
    case $OS in
        ubuntu)
            run_privileged apt-get install -y \
                vim \
                curl \
                wget \
                net-tools \
                telnet \
                htop \
                jq \
                git \
                tree \
                tmux
            ;;
        rocky|rhel|centos)
            run_privileged dnf install -y \
                vim \
                curl \
                wget \
                net-tools \
                telnet \
                htop \
                jq \
                git \
                tree \
                tmux
            ;;
    esac

    log_info "Common tools installed"
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
    
    # System configuration steps
    #configure_ssh
    configure_chrony
    configure_selinux
    disable_swap
    configure_kernel
    
    # Install components
    install_containerd
    install_kubernetes
    install_tools
    
    log_info "✅ Node setup completed successfully!"
    log_info "📝 Next steps:"
    log_info "  1. For control plane: sudo kubeadm init"
    log_info "  2. For worker nodes: join using the token from control plane"
    log_info "  3. Configure firewall rules if needed"
    
    # Show what was installed
    echo ""
    log_info "Installed versions:"
    echo "  - containerd: $(containerd --version 2>/dev/null || echo 'N/A')"
    echo "  - kubeadm: $(kubeadm version -o short 2>/dev/null || echo 'N/A')"
    echo "  - kubectl: $(kubectl version --client -o short 2>/dev/null || echo 'N/A')"
    echo "  - kubelet: $(kubelet --version 2>/dev/null || echo 'N/A')"
    
    # Show SELinux status for Rocky
    if [[ "$OS" == "rocky" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        echo ""
        log_info "SELinux status: $(getenforce)"
    fi
    
    # Show chrony status
    echo ""
    log_info "Time synchronization status:"
    run_privileged timedatectl status 2>/dev/null || echo "N/A"
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