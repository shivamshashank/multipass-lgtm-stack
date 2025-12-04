#!/bin/bash
# 08_deploy_stack.sh
# ---------------------------------------------
# 🚀 Deploying LGTM Stack (Loki, Grafana, Tempo, Monitor)
# ---------------------------------------------
set -e

# Explicitly load kubeconfig
export KUBECONFIG=/home/ubuntu/.kube/config

echo "⏳ [Pre-Check] Waiting for NGINX Ingress to be ready (max 3 mins)..."
# This command blocks until NGINX is actually running.
# If it's ready instantly, it continues instantly. If not, it waits up to 180s.
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || echo "⚠️ NGINX didn't report ready, but trying to proceed..."

# --- SAFETY FIX: Delete the validation webhook if it's stuck ---
# If NGINX is slow, this webhook prevents us from installing Grafana. 
# Deleting it allows the install to proceed safely.
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission 2>/dev/null || true

echo "🚀 [7/7] Deploying LGTM Stack..."

VM_IP=$(hostname -I | awk '{print $1}')

# 1. Create Namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 2. Deploy Components
echo "    -> Installing Loki..."
helm upgrade --install loki grafana/loki -n monitoring -f loki-values.yaml
helm upgrade --install promtail grafana/promtail -n monitoring --set "config.clients[0].url=http://loki:3100/loki/api/v1/push"

echo "    -> Installing Tempo..."
helm upgrade --install tempo grafana/tempo -n monitoring --set "tempo.receiver.otlp.protocols.grpc.endpoint=0.0.0.0:4317" --set "tempo.receiver.otlp.protocols.http.endpoint=0.0.0.0:4318"

echo "    -> Installing Prometheus/Grafana (Wait ~60s)..."
# Added --timeout 5m to give it plenty of time to start up
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f stack-values.yaml \
  --wait \
  --timeout 5m

echo "    -> Installing OpenTelemetry Collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector -n monitoring -f otel-values.yaml

echo ""
echo "=================================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=================================================="
echo "🖥️  Grafana URL: http://grafana.${VM_IP}.nip.io"
echo "🔑 Login:       admin / admin"
echo ""
echo "⚡ Test Command:"
echo "kubectl run trace-gen --image=ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:latest --restart=Never -- traces --otlp-insecure --otlp-endpoint=otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317 --rate=10 --duration=10m"
echo "=================================================="