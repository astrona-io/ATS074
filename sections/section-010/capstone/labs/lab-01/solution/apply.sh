#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet set env deployment/shuttle \
  OTEL_SERVICE_NAME=shuttle \
  "OTEL_RESOURCE_ATTRIBUTES=service.namespace=starfleet,service.version=1.0.0,deployment.environment.name=training" \
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta \
  OTEL_METRICS_EXEMPLAR_FILTER=trace_based
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
kubectl apply -f "$DIR/solution.yaml"
echo "[solution] Applied."
