#!/usr/bin/env bash
# Check: fresh spans and fresh metrics reach the Collector.
set -uo pipefail

for i in $(seq 1 40); do
  log="$(kubectl -n starfleet logs deploy/collector --since=30s 2>/dev/null)"
  if echo "$log" | grep -Eq 'Name +: dock' && echo "$log" | grep -Eq 'Name: +shuttle\.docks'; then
    echo "PASS: fresh dock spans and shuttle.docks metrics reached the Collector"
    exit 0
  fi
  sleep 3
done
echo "FAIL: the Collector did not receive both fresh dock spans and shuttle.docks metrics in the last two minutes"
exit 1
