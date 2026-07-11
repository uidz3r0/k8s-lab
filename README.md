# AJ's Kubernetes Home Lab 

## Quick Start on Your Laptop

```bash
# On your main laptop (control)
cd ~
mkdir -p k8s-lab
cd k8s-lab

# Initialize with my structure
curl -s https://gist.github.com/your-gist-url/setup-lab.sh | bash

# Or create manually
mkdir -p scripts/{setup,management,monitoring,utils}
mkdir -p manifests/{ingress,storage,apps}
mkdir -p configs docs

# Create your first script
cat > scripts/setup/01-node-setup.sh << 'EOF'
#!/bin/bash
echo "Node setup script..."
EOF
chmod +x scripts/setup/*.sh

# Sync to all nodes
for node in luke han leia; do
    rsync -avz ~/k8s-lab/ $node@10.1.1.10:~/k8s-lab/ 2>/dev/null || true
done
```

---

## Security Tips

1. Never store secrets in scripts - Use environment variables or Vault
2. Add .gitignore for sensitive files
3. Use `set -e` in scripts to fail fast
4. Log outputs - `script.sh 2>&1 | tee script.log`
5. Backup your scripts to **GitHub/GitLab**

### Security Best PRactices

```bash
# ✅ DO: Run with sudo, keep your environment
sudo ./node-setup.sh

# Or with a specific Kubernetes version
sudo ./01-node-setup.sh --version 1.33

# Verify SSH works after script
ssh user@10.1.1.10  # Should connect

# Check SELinux on Rocky
getenforce  # Should show "Permissive"

# Check time sync on any node
timedatectl status
chronyc sources -v

# ✅ DO: Use sudo for individual commands
sudo apt-get install kubeadm

# ✅ DO: Save kubeconfig to user's home
kubectl config view > ~/.kube/config

# ❌ DON'T: Become root
sudo su -
./node-setup.sh  # Bad! Configs go to /root/

# ❌ DON'T: Run as root directly
su -
./node-setup.sh  # Bad! Environment issues

# ❌ DON'T: Use sudo with piped commands
sudo cat /etc/passwd | grep root  # Only cat runs as root 
```

### Quick Check After Running

```bash
# Check who owns the kubeconfig
ls -la ~/.kube/config
# Should be owned by your user, NOT root

# Check if kubectl works
kubectl get nodes 2>/dev/null && echo "✅ kubectl works" || echo "❌ kubectl needs config"

# Verify no root-owned files in your home
find ~ -user root 2>/dev/null

# SSH status
sudo systemctl status sshd | grep "active (running)"

# Chrony status
sudo systemctl status chronyd | grep "active (running)"
chronyc tracking

# SELinux (Rocky only)
getenforce
cat /etc/selinux/config | grep SELINUX=

# Swap disabled
swapon --show  # Should output nothing
grep swap /etc/fstab  # Should be commented out

# Kernel modules loaded
lsmod | grep -E "overlay|br_netfilter"

# Sysctl settings
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
```