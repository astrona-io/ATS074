#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl -n starfleet create secret generic collector-auth \
  --from-literal=otlp-headers='x-starfleet-token=hailing-frequency-7'

kubectl -n starfleet set env deploy/shuttle \
  OTEL_SERVICE_NAME=shuttle \
  OTEL_EXPORTER_OTLP_TRACES_ENDPOINT- \
  OTEL_RESOURCE_ATTRIBUTES="service.namespace=starfleet,deployment.environment.name=production,service.version=3.0.0" \
  OTEL_TRACES_SAMPLER=parentbased_traceidratio \
  OTEL_TRACES_SAMPLER_ARG=0.25 \
  OTEL_BSP_SCHEDULE_DELAY=1000 \
  OTEL_METRIC_EXPORT_INTERVAL=5000

kubectl -n starfleet patch deploy shuttle --patch-file "$DIR/patch-headers.yaml"
kubectl -n starfleet rollout status deploy/shuttle --timeout=300s
echo "[solution] Applied."
