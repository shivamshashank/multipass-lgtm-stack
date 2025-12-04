#!/bin/bash
# 05_cluster_init.sh
# ---------------------------------------------
# 🏗️  Cluster Initialization
# ---------------------------------------------
set -e

echo "🏗️  [4/7] Initializing Kubernetes Cluster..."

# 1. Pre-pull images
sudo kubeadm config images pull

# 2. Init Cluster (Only if not already running)
if [ ! -f /etc/kubernetes/admin.conf ]; then
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16
else
    echo "    Cluster already initialized. Skipping init."
fi

# 3. Configure Kubeconfig explicitly for 'ubuntu' user
# (Using explicit paths because this script runs as sudo/root)
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# 4. Remove Control Plane Taint
# We need to specify the kubeconfig here because we are running as root
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

echo "✅ Cluster Initialized."