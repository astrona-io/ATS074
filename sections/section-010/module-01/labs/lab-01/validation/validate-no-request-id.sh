#!/usr/bin/env bash
# Check: the resource has no per-request attribute.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

attrs="$(env_value OTEL_RESOURCE_ATTRIBUTES)"
if echo "$attrs" | tr ',' '\n' | grep -qE '^request\.id='; then
  echo "FAIL: OTEL_RESOURCE_ATTRIBUTES still contains request.id"
  exit 1
fi
echo "PASS: no request.id on the resource"
