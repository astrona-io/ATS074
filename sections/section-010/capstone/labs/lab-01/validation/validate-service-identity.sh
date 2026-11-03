#!/usr/bin/env bash
# Check: the resource identifies the service and holds no per-request attribute.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

fail=0
name="$(env_value OTEL_SERVICE_NAME)"
if [ -z "$name" ]; then
  name="$(resource_attr service.name)"
fi
if [ "$name" != "shuttle" ]; then
  echo "FAIL: the effective service name is '${name:-unset}', expected shuttle"
  fail=1
fi
for pair in service.namespace=starfleet service.version=1.0.0 deployment.environment.name=training; do
  key="${pair%%=*}"
  want="${pair#*=}"
  got="$(resource_attr "$key")"
  if [ "$got" != "$want" ]; then
    echo "FAIL: resource attribute $key is '${got:-missing}', expected $want"
    fail=1
  fi
done
if env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -qE '^request\.id='; then
  echo "FAIL: OTEL_RESOURCE_ATTRIBUTES still contains request.id"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: the resource identifies the service and has no request.id"
fi
exit "$fail"
