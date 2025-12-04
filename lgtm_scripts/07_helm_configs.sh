#!/bin/bash
# 07_helm_configs.sh
# ---------------------------------------------
# ⚓ Helm Setup & Config Generation
# ---------------------------------------------
set -e

echo "📝 [6/7] Setting up Helm & Generating Configs..."

# 1. Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# 2. Generate Loki Config (Low Memory)
cat <<EOF > loki-values.yaml
deploymentMode: SingleBinary
loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: 'filesystem'
  schemaConfig:
    configs:
      - from: 2024-01-01
        store: tsdb
        object_store: filesystem
        schema: v13
        index:
          prefix: index_
          period: 24h

# --- FIX: Explicitly disable Scalable components ---
read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0

# Enable Single Binary
singleBinary:
  replicas: 1
  persistence:
    enabled: true
    size: 5Gi

# Reduce memory for demo
chunksCache:
  resources:
    requests:
      memory: 64Mi
    limits:
      memory: 256Mi
EOF

# 3. Generate OTel Config
cat <<EOF > otel-values.yaml
mode: deployment
image:
  repository: "otel/opentelemetry-collector-contrib"
config:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"
        http:
          endpoint: "0.0.0.0:4318"
  processors:
    batch: {}
  exporters:
    otlp:
      endpoint: "tempo.monitoring.svc.cluster.local:4317"
      tls:
        insecure: true
  service:
    pipelines:
      logs: null
      metrics: null
      traces:
        receivers: [otlp]
        processors: [batch]
        exporters: [otlp]
EOF

# 4. Generate Stack Config (Dynamic IP)
VM_IP=$(hostname -I | awk '{print $1}')
echo "    Targeting VM IP: $VM_IP"

cat <<EOF > stack-values.yaml
grafana:
  adminPassword: "admin"
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    hosts:
      - grafana.${VM_IP}.nip.io
    path: /
  grafana.ini:
    server:
      root_url: http://grafana.${VM_IP}.nip.io
  additionalDataSources:
    - name: Loki
      type: loki
      uid: loki
      url: http://loki:3100
      access: proxy
      jsonData:
        derivedFields:
          - datasourceUid: tempo
            matcherRegex: "traceID=(\\\\w+)"
            name: TraceID
            url: "\$\${__value.raw}"
    - name: Tempo
      type: tempo
      uid: tempo
      url: http://tempo.monitoring.svc.cluster.local:3200
      access: proxy
EOF

echo "✅ Configs Generated."