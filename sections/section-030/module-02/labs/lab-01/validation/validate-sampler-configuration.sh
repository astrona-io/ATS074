#!/usr/bin/env bash
# Check: sampler and endpoint settings on the Deployment.
set -uo pipefail

env_json="$(kubectl -n starfleet get deploy shuttle -o json | jq '.spec.template.spec.containers[0].env')"
value_of() { echo "$env_json" | jq -r --arg name "$1" '.[] | select(.name == $name) | .value // empty'; }

fail=0
sampler="$(value_of OTEL_TRACES_SAMPLER | tr '[:upper:]' '[:lower:]')"
arg="$(value_of OTEL_TRACES_SAMPLER_ARG)"
endpoint="$(value_of OTEL_EXPORTER_OTLP_ENDPOINT)"

if [ "$sampler" != "parentbased_traceidratio" ]; then
  echo "FAIL: OTEL_TRACES_SAMPLER is '${sampler}', expected parentbased_traceidratio"; fail=1
fi
if ! awk -v a="$arg" 'BEGIN { exit !(a != "" && a + 0 == 0.5) }'; then
  echo "FAIL: OTEL_TRACES_SAMPLER_ARG is '${arg}', expected 0.5"; fail=1
fi
case "$endpoint" in
  http://collector:4318|http://collector:4318/|http://collector.starfleet:4318|http://collector.starfleet.svc:4318|http://collector.starfleet.svc.cluster.local:4318) ;;
  *) echo "FAIL: OTEL_EXPORTER_OTLP_ENDPOINT is '${endpoint}', expected the collector HTTP port 4318"; fail=1 ;;
esac

[ "$fail" -eq 0 ] && echo "PASS: sampler and endpoint are configured"
exit "$fail"
