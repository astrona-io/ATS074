#!/usr/bin/env bash
# Check: the resource attributes name the namespace, version and environment.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

fail=0
check_attr() {
  local key="$1" want="$2" got
  got="$(resource_attr "$key")"
  if [ "$got" != "$want" ]; then
    echo "FAIL: resource attribute $key is '${got:-missing}', expected $want"
    fail=1
  fi
}
check_attr service.namespace starfleet
check_attr service.version 1.0.0
check_attr deployment.environment.name training
if [ "$fail" -eq 0 ]; then
  echo "PASS: the resource names the namespace, the version and the environment"
fi
exit "$fail"
