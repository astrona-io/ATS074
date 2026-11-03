#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet set env deployment/shuttle \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4318 \
  OTEL_TRACES_SAMPLER=parentbased_traceidratio \
  OTEL_TRACES_SAMPLER_ARG=0.25 \
  OTEL_BSP_MAX_QUEUE_SIZE=4096 \
  OTEL_BSP_MAX_EXPORT_BATCH_SIZE=512 \
  OTEL_BSP_SCHEDULE_DELAY=2000 \
  OTEL_METRIC_EXPORT_INTERVAL=5000 \
  OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta \
  SHUTTLE_VIEWS=keys,drop-fuel \
  OTEL_BLRP_MAX_QUEUE_SIZE=2048 \
  OTEL_BLRP_MAX_EXPORT_BATCH_SIZE=512 \
  SHUTTLE_ON_TERM=shutdown
kubectl -n starfleet patch deployment shuttle --type=merge \
  -p '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":30}}}}'
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s

observed="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sed -e "s/OBSERVED_AT/${observed}/" "$DIR/solution.yaml" | kubectl apply -f -
echo "[solution] Applied."
