#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deployment/shuttle \
  OTEL_TRACES_SAMPLER=parentbased_traceidratio \
  OTEL_TRACES_SAMPLER_ARG=0.5 \
  SHUTTLE_SPAN_PROCESSOR=batch \
  OTEL_BSP_MAX_QUEUE_SIZE=4096 \
  OTEL_BSP_MAX_EXPORT_BATCH_SIZE=256 \
  OTEL_BSP_SCHEDULE_DELAY=2000 \
  SHUTTLE_ON_TERM=shutdown
kubectl -n starfleet patch deployment shuttle --type=merge \
  -p '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":30}}}}'
kubectl -n starfleet rollout status deployment/shuttle --timeout=600s
echo "[solution] Applied."
