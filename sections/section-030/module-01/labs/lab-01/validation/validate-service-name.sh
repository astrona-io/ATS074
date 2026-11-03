#!/usr/bin/env bash
# Check: the Collector receives fresh telemetry with service.name shuttle.
set -uo pipefail

for i in $(seq 1 40); do
  if kubectl -n starfleet logs deploy/collector --since=30s 2>/dev/null | grep -Eq 'service\.name: Str\(shuttle\)'; then
    echo "PASS: the Collector received telemetry with service.name shuttle"
    exit 0
  fi
  sleep 3
done
echo "FAIL: no telemetry with service.name shuttle reached the Collector in the last two minutes"
exit 1
