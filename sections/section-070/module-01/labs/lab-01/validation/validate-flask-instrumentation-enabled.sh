#!/usr/bin/env bash
# Check: flask is not disabled and server spans reach the Collector.
set -uo pipefail

disabled="$(kubectl -n starfleet get deployment scout -o json 2>/dev/null | jq -r '[.spec.template.spec.containers[0].env[]? | select(.name=="OTEL_PYTHON_DISABLED_INSTRUMENTATIONS") | .value] | join(",")')"
if echo "$disabled" | tr ',' '\n' | sed 's/ //g' | grep -qx 'flask'; then
  echo "FAIL: OTEL_PYTHON_DISABLED_INSTRUMENTATIONS still contains flask ($disabled)"
  exit 1
fi
if echo "$disabled" | tr ',' '\n' | sed 's/ //g' | grep -qx 'requests'; then
  echo "FAIL: the requests instrumentation must stay on"
  exit 1
fi

for i in $(seq 1 30); do
  if kubectl -n starfleet logs deploy/collector --since=45s 2>/dev/null | grep -qE 'Name +: GET /(relay|dock)'; then
    echo "PASS: server spans for scout reach the Collector"
    exit 0
  fi
  sleep 5
done
echo "FAIL: no GET /relay or GET /dock span in the last 45 seconds of the Collector log"
exit 1
