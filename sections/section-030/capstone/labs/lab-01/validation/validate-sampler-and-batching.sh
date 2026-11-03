#!/usr/bin/env bash
# Check: sampler, batch delay and metric interval on the Deployment.
set -uo pipefail

env_json="$(kubectl -n starfleet get deploy shuttle -o json | jq '.spec.template.spec.containers[0].env')"
value_of() { echo "$env_json" | jq -r --arg name "$1" '.[] | select(.name == $name) | .value // empty'; }

fail=0
sampler="$(value_of OTEL_TRACES_SAMPLER | tr '[:upper:]' '[:lower:]')"
arg="$(value_of OTEL_TRACES_SAMPLER_ARG)"
delay="$(value_of OTEL_BSP_SCHEDULE_DELAY)"
interval="$(value_of OTEL_METRIC_EXPORT_INTERVAL)"

[ "$sampler" = "parentbased_traceidratio" ] || { echo "FAIL: OTEL_TRACES_SAMPLER is '${sampler}', expected parentbased_traceidratio"; fail=1; }
awk -v a="$arg" 'BEGIN { exit !(a != "" && a + 0 == 0.25) }' || { echo "FAIL: OTEL_TRACES_SAMPLER_ARG is '${arg}', expected 0.25"; fail=1; }
if ! [[ "$delay" =~ ^[0-9]+$ ]] || [ "$delay" -gt 2000 ]; then
  echo "FAIL: OTEL_BSP_SCHEDULE_DELAY must be at most 2000 milliseconds, got '${delay}'"; fail=1
fi
if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -gt 10000 ]; then
  echo "FAIL: OTEL_METRIC_EXPORT_INTERVAL must be at most 10000 milliseconds, got '${interval}'"; fail=1
fi

[ "$fail" -eq 0 ] && echo "PASS: sampler and intervals are configured"
exit "$fail"
