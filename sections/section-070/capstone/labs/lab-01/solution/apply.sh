#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/agent-config.yaml"
# Remove the hostPath volume (index 1) and its mount (index 1) from the agent.
kubectl -n starfleet patch daemonset agent --type=json -p '[
  {"op":"remove","path":"/spec/template/spec/containers/0/volumeMounts/1"},
  {"op":"remove","path":"/spec/template/spec/volumes/1"}
]'
kubectl -n starfleet set env deployment/scout \
  OTEL_PYTHON_DISABLED_INSTRUMENTATIONS- \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://agent:4318 \
  OTEL_SERVICE_NAME=scout \
  OTEL_PYTHON_EXCLUDED_URLS=healthz
kubectl -n starfleet rollout restart daemonset/agent
kubectl -n starfleet rollout status daemonset/agent --timeout=300s
kubectl -n starfleet rollout status deployment/scout --timeout=420s
echo "[solution] Applied."
