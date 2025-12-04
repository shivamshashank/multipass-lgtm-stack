#!/bin/bash
# 02_vm_prep.sh
# ---------------------------------------------
# 🔧 System Prerequisites & Kernel Modules
# ---------------------------------------------
set -e

echo "🔧 [1/7] Disabling Swap & Loading Modules..."

# 1. Disable Swap (Required for K8s)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Kernel Modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Sysctl Networking
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# 4. Basic Tools
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg pigz net-tools

echo "✅ System Prep Complete."