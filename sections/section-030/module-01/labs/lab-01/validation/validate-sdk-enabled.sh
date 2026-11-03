#!/usr/bin/env bash
# Check: the SDK is enabled. OTEL_SDK_DISABLED disables it only for the
# case-insensitive text "true".
set -uo pipefail

if ! kubectl -n starfleet rollout status deploy/shuttle --timeout=300s >/dev/null 2>&1; then
  echo "FAIL: the shuttle Deployment is not rolled out"
  exit 1
fi

disabled="$(kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name == "OTEL_SDK_DISABLED") | .value' | tr '[:upper:]' '[:lower:]')"
if [ "$disabled" = "true" ]; then
  echo "FAIL: OTEL_SDK_DISABLED is true, so the SDK records nothing"
  exit 1
fi
echo "PASS: the SDK is enabled and shuttle is rolled out"
