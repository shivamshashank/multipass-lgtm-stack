#!/bin/bash
# 03_containerd_setup.sh
# ---------------------------------------------
# 📦 Containerd Runtime Setup
# ---------------------------------------------
set -e

echo "📦 [2/7] Installing & Configuring Containerd..."

# 1. Install
sudo apt-get install -y containerd

# 2. Generate Default Config
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# 3. Enable SystemdCgroup (Crucial for Kubeadm)
echo "    Enabling SystemdCgroup..."
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 4. Restart
sudo systemctl restart containerd

echo "✅ Containerd Ready."