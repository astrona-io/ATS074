#!/usr/bin/env bash
# Check: the example application is still in place. Deleting the Collector,
# swapping the script or changing the image is not a fix.
set -uo pipefail

fail=0

for name in collector shuttle; do
  available="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  if [ -z "$available" ] || [ "$available" -lt 1 ]; then
    echo "FAIL: deployment $name has no available replica (a new pod can need a few minutes to install the SDK)"
    fail=1
  fi
done

image="$(kubectl -n starfleet get deployment shuttle -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
if [ "$image" != "python:3.12-slim" ]; then
  echo "FAIL: shuttle must keep the image python:3.12-slim, found '$image'"
  fail=1
fi

if ! kubectl -n starfleet get configmap shuttle-app -o json | jq -e '.data["app.py"] | contains("BatchSpanProcessor")' >/dev/null 2>&1; then
  echo "FAIL: the shuttle-app ConfigMap was changed; fix the environment, not the script"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: collector and shuttle are available with their original image and script"
fi
exit "$fail"
