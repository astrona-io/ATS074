#!/usr/bin/env bash
# Check: the Deployment asks for delta temporality.
set -uo pipefail

env_value() {
  kubectl -n starfleet get deploy shuttle -o json 2>/dev/null \
    | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}
resource_attr() {
  env_value OTEL_RESOURCE_ATTRIBUTES | tr ',' '\n' | grep -E "^$1=" | head -1 | cut -d= -f2-
}

value="$(env_value OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE | tr 'A-Z' 'a-z')"
if [ "$value" = "delta" ]; then
  echo "PASS: temporality preference is delta"
  exit 0
fi
echo "FAIL: OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE is '${value:-unset}', expected delta"
exit 1
