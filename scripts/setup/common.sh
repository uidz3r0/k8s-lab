#!/bin/bash

echo "Updating system..."

if command -v dnf >/dev/null; then
    sudo dnf update -y
fi

if command -v apt >/dev/null; then
    sudo apt update
    sudo apt upgrade -y
fi

echo
echo "Disabling swap..."

sudo swapoff -a

sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab

echo
echo "Loading kernel modules..."

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo
echo "Configuring sysctl..."

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

echo
echo "Done."