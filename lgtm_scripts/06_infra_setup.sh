#!/bin/bash
# 06_infra_setup.sh
# ---------------------------------------------
# 🌐 Infrastructure (Network, Storage, Ingress)
# ---------------------------------------------
set -e

# Because this runs as SUDO, we must explicitly point to the admin config
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "🌐 [5/7] Deploying Infrastructure..."

# 1. Calico Networking
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

# 2. Local Path Storage
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# 3. NGINX Ingress (Host Network Mode)
# This allows us to access Grafana via the VM IP directly
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/baremetal/deploy.yaml
kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type='json' -p='[{"op": "add", "path": "/spec/template/spec/hostNetwork", "value":true}]'

echo "✅ Infrastructure Deployed."