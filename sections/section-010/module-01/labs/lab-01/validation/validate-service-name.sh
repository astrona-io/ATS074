#!/usr/bin/env bash
# Check: the effective service.name is shuttle (OTEL_SERVICE_NAME wins over the resource attribute).
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

name="$(env_value OTEL_SERVICE_NAME)"
if [ -z "$name" ]; then
  name="$(resource_attr service.name)"
fi
if [ "$name" = "shuttle" ]; then
  echo "PASS: the service name is shuttle"
  exit 0
fi
echo "FAIL: the effective service name is '${name:-unset}', expected shuttle"
exit 1
