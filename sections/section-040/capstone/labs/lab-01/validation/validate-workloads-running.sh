#!/usr/bin/env bash
# Check: the fixes did not remove the workloads. Rejects deleting a Deployment,
# scaling it to zero, swapping an image or replacing the application code.
set -uo pipefail

fail=0
NS=starfleet

expect_available() {
  local name="$1" image="$2" ready actual
  ready="$(kubectl -n "$NS" get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ -z "$ready" ] || [ "$ready" -lt 1 ]; then
    echo "FAIL: deployment $name has no available replica"
    fail=1
  fi
  actual="$(kubectl -n "$NS" get deployment "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if [ "$actual" != "$image" ]; then
    echo "FAIL: deployment $name runs image '$actual', expected '$image'"
    fail=1
  fi
}

expect_available collector otel/opentelemetry-collector-contrib:0.164.0
expect_available shuttle python:3.12-slim

if ! kubectl -n "$NS" get configmap shuttle-app -o jsonpath='{.data.app\.py}' 2>/dev/null | grep -q 'LoggingHandler'; then
  echo "FAIL: the application code in ConfigMap shuttle-app no longer uses the logging bridge"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: collector and shuttle are available with their original images and code"
fi
exit "$fail"
