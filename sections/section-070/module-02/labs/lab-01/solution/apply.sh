#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -f "$DIR/agent-config.yaml"
kubectl -n starfleet set env deployment/shuttle OTEL_EXPORTER_OTLP_ENDPOINT=http://agent:4318
kubectl -n starfleet rollout restart daemonset/agent
kubectl -n starfleet rollout status daemonset/agent --timeout=300s
kubectl -n starfleet rollout status deployment/shuttle --timeout=420s
echo "[solution] Applied."
