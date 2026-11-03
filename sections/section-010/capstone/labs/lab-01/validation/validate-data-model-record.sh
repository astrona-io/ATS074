#!/usr/bin/env bash
# Check: the ConfigMap data-model-record holds the identity, the temporality and the unit.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

if ! kubectl -n starfleet get configmap data-model-record >/dev/null 2>&1; then
  echo "FAIL: ConfigMap data-model-record does not exist in starfleet"
  exit 1
fi
fail=0
get_key() { kubectl -n starfleet get configmap data-model-record -o json | jq -r --arg k "$1" '.data[$k] // ""'; }
identity="$(get_key service-identity)"
temporality="$(get_key temporality | tr 'A-Z' 'a-z')"
unit="$(get_key duration-unit)"
for token in shuttle starfleet 1.0.0 training; do
  if ! echo "$identity" | grep -q "$token"; then
    echo "FAIL: service-identity does not mention $token"
    fail=1
  fi
done
if [ "$temporality" != "delta" ]; then
  echo "FAIL: temporality is '${temporality:-missing}', expected delta"
  fail=1
fi
if [ "$unit" != "s" ]; then
  echo "FAIL: duration-unit is '${unit:-missing}', expected s (the unit the Collector shows for shuttle.request.duration)"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: data-model-record is complete"
fi
exit "$fail"
