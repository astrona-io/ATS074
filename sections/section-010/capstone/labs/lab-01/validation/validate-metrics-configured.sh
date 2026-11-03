#!/usr/bin/env bash
# Check: delta temporality and an exemplar filter that allows exemplars.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

fail=0
temporality="$(env_value OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE | tr 'A-Z' 'a-z')"
filter="$(env_value OTEL_METRICS_EXEMPLAR_FILTER | tr 'A-Z' 'a-z')"
if [ "$temporality" != "delta" ]; then
  echo "FAIL: temporality preference is '${temporality:-unset}', expected delta"
  fail=1
fi
if [ "$filter" != "trace_based" ] && [ "$filter" != "always_on" ]; then
  echo "FAIL: exemplar filter is '${filter:-unset}', expected trace_based or always_on"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: delta temporality and exemplar filter $filter"
fi
exit "$fail"
