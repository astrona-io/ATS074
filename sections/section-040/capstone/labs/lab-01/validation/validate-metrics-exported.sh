#!/usr/bin/env bash
# Check: the counter shuttle.dispatch.count reaches the collector within 40
# seconds, so the export interval is short.
set -uo pipefail

NS=starfleet
# The shuttle needs a minute to install the SDK after every change, so every
# check polls (up to about 150 seconds) for fresh telemetry in the collector log.
fresh_logs() { kubectl -n "$NS" logs deploy/collector --since="${1:-20}s" 2>/dev/null; }
wait_until() {
  local check="$1" i
  for i in $(seq 1 50); do
    if "$check"; then return 0; fi
    sleep 3
  done
  return 1
}

interval="$(kubectl -n "$NS" get deployment shuttle -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name == "OTEL_METRIC_EXPORT_INTERVAL") | .value' | head -n 1)"
if [ -n "$interval" ] && [ "$interval" -gt 15000 ] 2>/dev/null; then
  echo "FAIL: OTEL_METRIC_EXPORT_INTERVAL is $interval milliseconds, expected 15000 or less"
  exit 1
fi

metric_arrives() {
  fresh_logs 40 | grep -q 'shuttle.dispatch.count'
}

if wait_until metric_arrives; then
  echo "PASS: the metric shuttle.dispatch.count reaches the collector"
  exit 0
fi
echo "FAIL: the metric shuttle.dispatch.count did not reach the collector in the last 40 seconds"
exit 1
