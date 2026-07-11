#!/bin/bash

echo "===== containerd ====="
containerd --version
systemctl is-active containerd

echo
echo "===== kubelet ====="
kubelet --version
systemctl is-enabled kubelet

echo
echo "===== CRI ====="
crictl info >/dev/null && crictl version && echo "CRI OK" || echo "crictl not installed"

echo
echo "===== OCI Runtime ====="
if command -v runc >/dev/null 2>&1; then
    runc --version | head -1
else
    echo "runc not installed"
fi

echo
echo "===== cgroup ====="
grep SystemdCgroup /etc/containerd/config.toml

echo
echo "===== swap ====="
swapon --show

echo
echo "===== kernel modules ====="
lsmod | grep overlay
lsmod | grep br_netfilter

echo
echo "===== sysctl ====="
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward

echo
echo "===== Versions ====="
kubeadm version
kubectl version --client

echo
echo "===== Firewall ====="

if command -v firewall-cmd >/dev/null 2>&1; then
    systemctl is-active firewalld
elif command -v ufw >/dev/null 2>&1; then
    systemctl is-active ufw
else
    echo "No supported firewall service detected."
fi
