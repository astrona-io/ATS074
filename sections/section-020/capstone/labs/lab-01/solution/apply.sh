#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deploy/shuttle \
  SHUTTLE_CONFIGURE_SDK=true \
  OTEL_SERVICE_NAME=shuttle \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.starfleet.svc.cluster.local:4318 \
  SHUTTLE_SPAN_PROCESSORS=crew-tag,batch \
  OTEL_TRACES_SAMPLER=parentbased_traceidratio \
  OTEL_TRACES_SAMPLER_ARG=0.5 \
  OTEL_PROPAGATORS-
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s

# Wait for a batch with the SDK version and the environment attribute.
version=""
for attempt in $(seq 1 90); do
  version="$(kubectl -n starfleet logs deploy/collector --since=120s | grep "telemetry.sdk.version" | tail -1 | sed -e 's/.*Str(\(.*\))/\1/')"
  if [ -n "$version" ]; then
    break
  fi
  sleep 2
done
if [ -z "$version" ]; then
  echo "[solution] no telemetry arrived in time." >&2
  exit 1
fi

kubectl -n starfleet create configmap composability-evidence \
  --from-literal=tracer-class=Tracer \
  --from-literal=injected-headers=traceparent \
  --from-literal=telemetry-sdk-version="$version" \
  --from-literal=environment=staging
echo "[solution] Applied."
