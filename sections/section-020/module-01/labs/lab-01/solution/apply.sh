#!/usr/bin/env bash
# Applies the reference solution. Run only by `astrona test`.
set -euo pipefail

kubectl -n starfleet set env deploy/shuttle OTEL_SDK_DISABLED- OTEL_SERVICE_NAME=shuttle
kubectl -n starfleet rollout status deployment/shuttle --timeout=300s

# Wait for a batch of telemetry from the new pod, then read the SDK version.
version=""
for attempt in $(seq 1 60); do
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

kubectl -n starfleet create configmap api-sdk-evidence \
  --from-literal=tracer-class=Tracer \
  --from-literal=scope-name=starfleet.navigation \
  --from-literal=telemetry-sdk-version="$version" \
  --from-literal=service-name=shuttle
echo "[solution] Applied."
