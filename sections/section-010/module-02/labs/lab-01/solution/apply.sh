#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deployment/shuttle \
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta \
  OTEL_METRICS_EXEMPLAR_FILTER=trace_based
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s
echo "[solution] Applied."
