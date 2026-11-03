#!/usr/bin/env bash
# Check: the metric interval is short and fresh shuttle.docks metrics arrive.
set -uo pipefail

interval="$(kubectl -n starfleet get deploy shuttle -o json | jq -r '.spec.template.spec.containers[0].env[]? | select(.name == "OTEL_METRIC_EXPORT_INTERVAL") | .value')"
if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -gt 10000 ]; then
  echo "FAIL: OTEL_METRIC_EXPORT_INTERVAL must be a number of milliseconds of at most 10000, got '${interval}'"
  exit 1
fi

for i in $(seq 1 40); do
  if kubectl -n starfleet logs deploy/collector --since=30s 2>/dev/null | grep -Eq 'Name: +shuttle\.docks'; then
    echo "PASS: the Collector received fresh shuttle.docks metrics"
    exit 0
  fi
  sleep 3
done
echo "FAIL: no shuttle.docks metric reached the Collector in the last two minutes"
exit 1
