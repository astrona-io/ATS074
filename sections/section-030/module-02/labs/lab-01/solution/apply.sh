#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deploy/shuttle \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318 \
  OTEL_TRACES_SAMPLER=parentbased_traceidratio \
  OTEL_TRACES_SAMPLER_ARG=0.5 \
  OTEL_METRIC_EXPORT_INTERVAL=5000
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
echo "[solution] Applied."
