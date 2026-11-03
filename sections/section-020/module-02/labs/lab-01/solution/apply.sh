#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deploy/shuttle \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4318 \
  SHUTTLE_SPAN_PROCESSORS=crew-tag,batch \
  OTEL_BSP_SCHEDULE_DELAY=2000 \
  OTEL_TRACES_SAMPLER=parentbased_always_on
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s

kubectl -n starfleet create configmap pipeline-evidence \
  --from-literal=processors=crew-tag,batch \
  --from-literal=exporter-port=4318 \
  --from-literal=crew-size=4
echo "[solution] Applied."
