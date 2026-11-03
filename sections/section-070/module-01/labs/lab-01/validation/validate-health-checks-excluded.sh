#!/usr/bin/env bash
# Check: health check requests are excluded and scout still sends other spans.
set -uo pipefail

excluded="$(kubectl -n starfleet get deployment scout -o json 2>/dev/null | jq -r '[.spec.template.spec.containers[0].env[]? | select(.name=="OTEL_PYTHON_EXCLUDED_URLS") | .value] | first // ""')"
if ! echo "$excluded" | grep -q 'healthz'; then
  echo "FAIL: OTEL_PYTHON_EXCLUDED_URLS does not name healthz (now '$excluded')"
  exit 1
fi

for i in $(seq 1 30); do
  recent="$(kubectl -n starfleet logs deploy/collector --since=40s 2>/dev/null)"
  if echo "$recent" | grep -qE 'Name +: GET /(relay|dock)' && ! echo "$recent" | grep -q 'GET /healthz'; then
    echo "PASS: health checks are excluded and other spans still arrive"
    exit 0
  fi
  sleep 5
done
echo "FAIL: the last 40 seconds of the Collector log still show GET /healthz, or show no scout spans"
exit 1
