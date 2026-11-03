#!/usr/bin/env bash
# Check: scout exports to the agent and is configured through the environment.
set -uo pipefail

fail=0
env_value() {
  kubectl -n starfleet get deployment scout -o json 2>/dev/null | jq -r --arg n "$1" '[.spec.template.spec.containers[0].env[]? | select(.name==$n) | .value] | first // ""'
}

endpoint="$(env_value OTEL_EXPORTER_OTLP_ENDPOINT)"
case "$endpoint" in
  http://agent:4318*|http://agent.starfleet:4318*|http://agent.starfleet.svc:4318*|http://agent.starfleet.svc.cluster.local:4318*) ;;
  *) echo "FAIL: OTEL_EXPORTER_OTLP_ENDPOINT is '$endpoint', expected http://agent:4318"; fail=1 ;;
esac

disabled="$(env_value OTEL_PYTHON_DISABLED_INSTRUMENTATIONS)"
if echo "$disabled" | tr ',' '\n' | sed 's/ //g' | grep -qx 'flask'; then
  echo "FAIL: flask is still in OTEL_PYTHON_DISABLED_INSTRUMENTATIONS"
  fail=1
fi
if [ "$(env_value OTEL_SERVICE_NAME)" != "scout" ]; then
  echo "FAIL: OTEL_SERVICE_NAME must be scout"
  fail=1
fi
if ! env_value OTEL_PYTHON_EXCLUDED_URLS | grep -q 'healthz'; then
  echo "FAIL: OTEL_PYTHON_EXCLUDED_URLS must name healthz"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: scout exports to the agent and its agent settings are right"
fi
exit "$fail"
