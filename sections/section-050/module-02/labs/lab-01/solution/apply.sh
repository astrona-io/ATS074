#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deployment/shuttle \
  OTEL_METRIC_EXPORT_INTERVAL=5000 \
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta \
  SHUTTLE_VIEWS=keys,buckets,drop-fuel \
  OTEL_BLRP_MAX_QUEUE_SIZE=2048 \
  OTEL_BLRP_MAX_EXPORT_BATCH_SIZE=512
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
echo "[solution] Applied."
