#!/usr/bin/env bash
# Check: the Collector and the shuttle service are still available with their original images.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

fail=0
for pair in "collector:otel/opentelemetry-collector-contrib:0.164.0" "shuttle:python:3.12-slim"; do
  name="${pair%%:*}"
  image="${pair#*:}"
  ready="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
  actual="$(kubectl -n starfleet get deployment "$name" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || true)"
  if [ -z "$ready" ] || [ "$ready" -lt 1 ]; then
    echo "FAIL: deployment $name has no available replica"
    fail=1
  fi
  if [ "$actual" != "$image" ]; then
    echo "FAIL: deployment $name runs image '$actual', expected '$image'"
    fail=1
  fi
done
if [ "$fail" -eq 0 ]; then
  echo "PASS: collector and shuttle are available with their original images"
fi
exit "$fail"
