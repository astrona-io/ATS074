#!/usr/bin/env bash
# Check: the exemplar filter lets measurements become exemplars.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

value="$(env_value OTEL_METRICS_EXEMPLAR_FILTER | tr 'A-Z' 'a-z')"
case "$value" in
  trace_based|always_on)
    echo "PASS: exemplar filter is $value"
    exit 0
    ;;
esac
echo "FAIL: OTEL_METRICS_EXEMPLAR_FILTER is '${value:-unset}', expected trace_based or always_on"
exit 1
