#!/usr/bin/env bash
# Check: fresh dock spans reach the Collector.
set -uo pipefail

for i in $(seq 1 40); do
  if kubectl -n starfleet logs deploy/collector --since=30s 2>/dev/null | grep -Eq 'Name +: dock'; then
    echo "PASS: the Collector received fresh dock spans"
    exit 0
  fi
  sleep 3
done
echo "FAIL: no dock span reached the Collector in the last two minutes"
exit 1
