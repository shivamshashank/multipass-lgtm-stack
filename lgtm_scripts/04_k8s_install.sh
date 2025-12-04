#!/bin/bash
# 04_k8s_install.sh
# ---------------------------------------------
# ☸️  Kubernetes Tools Installation
# ---------------------------------------------
set -e

echo "☸️  [3/7] Installing Kubernetes Binaries..."

# 1. Add Kubernetes Apt Key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes

# 2. Add Repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 3. Install Tools
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "✅ Kubernetes Tools Installed."